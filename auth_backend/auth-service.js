const { randomInt, randomUUID } = require('node:crypto');
const { AuthError, digest, secret, equal, normalizeEmail, validateProfile,
  validatePassword, hashPassword, verifyPassword, publicUser } = require('./security');

class AuthService {
  constructor({ store, sendEmail, verifyGoogle, now = () => new Date(), config = {} }) {
    this.store = store; this.sendEmail = sendEmail; this.verifyGoogle = verifyGoogle; this.now = now;
    this.config = { otpTtl: 300, attempts: 5, resend: 60, sessionTtl: 604800, ...config };
  }
  async requestOtp(emailValue, ip, purpose = 'registration') {
    if (!['registration', 'password_reset'].includes(purpose)) throw new AuthError(400, 'Mục đích OTP không hợp lệ.');
    const email = normalizeEmail(emailValue), now = this.now();
    await this.store.limit(`otp-ip:${digest(ip)}`, 3600, 20, now);
    await this.store.limit(`otp-email:${digest(email)}`, 3600, 10, now);
    await this.store.cooldown(`otp-cooldown:${digest(email)}`, this.config.resend, now);
    const existing = await this.store.findEmail(email);
    if (purpose === 'registration' && existing) throw new AuthError(409, 'Email đã được đăng ký. Vui lòng đăng nhập.');
    if (purpose === 'password_reset' && !existing) throw new AuthError(400, 'Không tìm thấy tài khoản với email này.');
    if (existing) this.requireActive(existing);
    const id = secret(), otp = String(randomInt(100000, 1000000));
    await this.store.putChallenge({ _id: id, email, purpose, otpHash: digest(`${id}:${otp}`),
      state: 'sending', attempts: 0, expiresAt: new Date(now.getTime() + this.config.otpTtl * 1000) });
    try {
      await this.sendEmail(email, otp, this.config.otpTtl);
      await this.store.activateChallenge(id);
    } catch (error) {
      await this.store.removeChallenge(id);
      throw error;
    }
    return { challengeId: id, expiresIn: this.config.otpTtl, resendAfter: this.config.resend };
  }
  async verifyOtp(challengeId, otp) {
    if (typeof challengeId !== 'string' || typeof otp !== 'string' || !/^\d{6}$/.test(otp)) {
      throw new AuthError(400, 'Mã OTP không hợp lệ.');
    }
    const now = this.now();
    const challenge = await this.store.attemptChallenge(challengeId, now, this.config.attempts);
    if (!challenge) throw new AuthError(400, 'OTP đã hết hạn, đã dùng hoặc vượt quá số lần thử. Vui lòng gửi lại.');
    const hash = digest(`${challengeId}:${otp}`);
    if (!equal(hash, challenge.otpHash)) {
      throw new AuthError(400, `Mã OTP không chính xác. Còn ${this.config.attempts - challenge.attempts} lần thử.`);
    }
    const proof = secret();
    if (!await this.store.verifyChallenge(challengeId, hash, digest(proof), now)) {
      throw new AuthError(400, 'OTP đã được sử dụng.');
    }
    return { registrationToken: proof, email: challenge.email };
  }
  async register({ registrationToken, name, phone, password }) {
    validateProfile(name, phone); validatePassword(password);
    if (typeof registrationToken !== 'string') throw new AuthError(401, 'Vui lòng xác minh OTP trước.');
    const proofHash = digest(registrationToken);
    const challenge = await this.store.claimProof(proofHash, this.now());
    if (!challenge) throw new AuthError(401, 'Xác minh đăng ký đã hết hạn hoặc đã được sử dụng.');
    try {
      if (challenge.purpose && challenge.purpose !== 'registration') throw new AuthError(403, 'Xác minh này không dành cho đăng ký.');
      const user = await this.store.createUser({ id: `c_${randomUUID()}`,
        email: challenge.email, emailNormalized: challenge.email, emailVerified: true,
        name: name.trim(), phone: phone.trim(), password_hash: await hashPassword(password),
        role: 'customer', totalSpent: 0, totalOrders: 0, memberTier: 'Đồng', isActive: true,
        identityActive: true, created_at: this.now().toISOString() });
      await this.store.consumeProof(proofHash);
      return this.issueSession(user);
    } catch (error) {
      // Keep the proof retryable for validation/database failures; unique email prevents two users.
      await this.store.releaseProof(proofHash);
      throw error;
    }
  }
  async login(emailValue, password, ip) {
    const email = normalizeEmail(emailValue), now = this.now();
    await this.store.limit(`login-ip:${digest(ip)}`, 900, 50, now);
    await this.store.limit(`login-email:${digest(email)}`, 900, 10, now);
    const user = await this.store.findEmail(email);
    if (!user || !await verifyPassword(password, user)) throw new AuthError(401, 'Email hoặc mật khẩu không chính xác.');
    this.requireActive(user);
    if (!(user.password_hash ?? '').startsWith('scrypt$')) {
      await this.store.upgradePassword(user.id, await hashPassword(password.trim()));
    }
    return this.issueSession(user);
  }
  async google(accessToken, ip = 'unknown', password) {
    if (typeof accessToken !== 'string' || !accessToken || accessToken.length > 16384) {
      throw new AuthError(401, 'Thiếu token Google hợp lệ.');
    }
    await this.store.limit(`google-ip:${digest(ip)}`, 900, 30, this.now());
    const identity = await this.verifyGoogle(accessToken);
    if (!identity.id || !identity.email_confirmed_at ||
        !identity.identities?.some(item => item.provider === 'google')) {
      throw new AuthError(401, 'Tài khoản Google chưa được xác minh.');
    }
    await this.store.limit(`google-uid:${digest(identity.id)}`, 900, 10, this.now());
    const email = normalizeEmail(identity.email);
    let user = await this.store.findGoogle(identity.id);
    if (!user) {
      user = await this.store.findEmail(email);
      if (user) {
        this.requireActive(user);
        // Privileged identities must not be linked based only on matching email.
        if (user.role === 'admin') throw new AuthError(403, 'Tài khoản quản trị cần đăng nhập bằng phương thức đã được cấp.');
        await this.authorizeGoogleLink(user, identity, password);
        user = await this.store.linkGoogle(user.id, identity.id);
      } else {
        try {
          user = await this.store.createUser({ id: `c_${randomUUID()}`, email, emailNormalized: email,
            emailVerified: true, supabaseUserId: identity.id, identityActive: true,
            name: '', phone: '', role: 'customer', isActive: true, totalOrders: 0,
            totalSpent: 0, memberTier: 'Đồng', created_at: this.now().toISOString() });
        } catch (error) {
          if (error.status !== 409) throw error;
          // Another callback/registration won the unique-index race. Preserve that ID.
          user = await this.store.findEmail(email);
          if (!user || user.role === 'admin') throw error;
          this.requireActive(user);
          await this.authorizeGoogleLink(user, identity, password);
          user = await this.store.linkGoogle(user.id, identity.id);
        }
      }
    }
    this.requireActive(user);
    return this.issueSession(user, 'google');
  }
  async authorizeGoogleLink(user, identity, password) {
    if (user.emailVerified === true || user.supabaseUserId === identity.id) return;
    if (!password) throw new AuthError(409,
      'Nhập mật khẩu tài khoản cũ để liên kết Google.', 'account_link_required');
    if (!await verifyPassword(password, user)) throw new AuthError(401, 'Mật khẩu tài khoản cũ không chính xác.');
    if (!(user.password_hash ?? '').startsWith('scrypt$')) {
      await this.store.upgradePassword(user.id, await hashPassword(password.trim()));
    }
  }
  requireActive(user) {
    if (user.isActive === false) throw new AuthError(403, 'Tài khoản đã bị khóa. Vui lòng liên hệ CSKH.');
  }
  async issueSession(user, provider = 'password') {
    this.requireActive(user);
    const token = secret(), expiresAt = new Date(this.now().getTime() + this.config.sessionTtl * 1000);
    await this.store.putSession({ _id: digest(token), userId: user.id, provider, expiresAt });
    return { token, expiresAt: expiresAt.toISOString(), customer: publicUser({ ...user, sessionProvider: provider }) };
  }
  async authenticate(token) {
    if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) throw new AuthError(401, 'Phiên đăng nhập không hợp lệ.');
    const session = await this.store.getSession(digest(token), this.now());
    if (!session) throw new AuthError(401, 'Phiên đăng nhập đã hết hạn.');
    const user = await this.store.findId(session.userId);
    if (!user) throw new AuthError(401, 'Tài khoản không tồn tại.');
    this.requireActive(user);
    return { ...user, sessionProvider: session.provider, sessionExpiresAt: session.expiresAt.toISOString() };
  }
  async saveProfile(user, { name, phone, password }) {
    validateProfile(name, phone);
    const fields = { name: name.trim(), phone: phone.trim() };
    if (password) {
      if (publicUser(user).hasPassword) throw new AuthError(409, 'Tài khoản đã có mật khẩu. Không thay đổi mật khẩu ở bước hồ sơ.');
      validatePassword(password);
      fields.password_hash = await hashPassword(password);
    }
    const updated = await this.store.updateProfile(user.id, fields, Boolean(password));
    return publicUser({ ...updated, sessionProvider: user.sessionProvider });
  }
  async logout(token) {
    if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) throw new AuthError(401, 'Phiên đăng nhập không hợp lệ.');
    await this.store.deleteSession(digest(token));
  }
  async resetPassword({ registrationToken, password }) {
    validatePassword(password);
    if (typeof registrationToken !== 'string') throw new AuthError(401, 'Vui lòng xác minh OTP.');
    const proofHash = digest(registrationToken);
    const proof = await this.store.claimProof(proofHash, this.now());
    if (!proof) throw new AuthError(401, 'Xác minh đã hết hạn hoặc đã được sử dụng.');
    try {
      if (proof.purpose !== 'password_reset') throw new AuthError(403, 'Xác minh này không dành cho đặt lại mật khẩu.');
      const user = await this.store.findEmail(proof.email);
      if (!user) throw new AuthError(404, 'Không tìm thấy tài khoản.');
      this.requireActive(user);
      await this.store.upgradePassword(user.id, await hashPassword(password));
      await this.store.deleteUserSessions(user.id);
      await this.store.consumeProof(proofHash);
    } catch (error) { await this.store.releaseProof(proofHash); throw error; }
  }
  async changeAdminPassword(user, { oldPassword, newPassword }) {
    if (user.role !== 'admin') throw new AuthError(403, 'Không có quyền quản trị.');
    validatePassword(newPassword);
    await this.store.limit(`password-user:${digest(user.id)}`, 900, 10, this.now());
    if (!await verifyPassword(oldPassword, user)) throw new AuthError(400, 'Mật khẩu hiện tại không chính xác.', 'wrong_password');
    await this.store.upgradePassword(user.id, await hashPassword(newPassword));
  }
}
module.exports = { AuthService };
