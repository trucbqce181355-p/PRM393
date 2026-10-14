const { randomInt, randomUUID } = require('node:crypto');
const { AuthError, digest, secret, equal, normalizeEmail, validateProfile, validatePassword, hashPassword, verifyPassword, publicUser } = require('./security');

class AuthService {
  constructor({ store, sendEmail, now = () => new Date(), config = {} }) {
    this.store = store; this.sendEmail = sendEmail; this.now = now;
    this.config = { otpTtl: 300, attempts: 5, resend: 60, sessionTtl: 604800, ...config };
  }
  async requestOtp(emailValue, ip) {
    const email = normalizeEmail(emailValue), now = this.now();
    await this.store.limit(`otp-ip:${digest(ip)}`, 3600, 20, now);
    await this.store.limit(`otp-email:${digest(email)}`, 3600, 10, now);
    await this.store.cooldown(`otp-cooldown:${digest(email)}`, this.config.resend, now);
    if (await this.store.findEmail(email)) throw new AuthError(409, 'Email đã được đăng ký. Vui lòng đăng nhập.');
    const id = secret(), otp = String(randomInt(100000, 1000000));
    await this.store.putChallenge({ _id: id, email, otpHash: digest(`${id}:${otp}`),
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
      const user = await this.store.createUser({ id: `c_${randomUUID()}`,
        email: challenge.email, emailNormalized: challenge.email, emailVerified: true,
        name: name.trim(), phone: phone.trim(), password_hash: await hashPassword(password),
        role: 'customer', totalSpent: 0, totalOrders: 0, memberTier: 'Đồng', isActive: true,
        identityActive: true, created_at: this.now().toISOString() });
      await this.store.consumeProof(proofHash);
      return { customer: publicUser(user) };
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
    return { ...user, sessionProvider: session.provider };
  }
}
module.exports = { AuthService };
