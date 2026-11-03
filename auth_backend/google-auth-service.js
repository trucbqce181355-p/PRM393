// Author: Chih An (GitHub: ChangChinAn)
// UC06–UC07: Đăng nhập Google và liên kết tài khoản email cùng địa chỉ.
const { randomBytes, randomUUID } = require('node:crypto');
const { digest } = require('./otp-request-service');
const { verifyPassword, hashPassword } = require('./password-security');

class GoogleAuthError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class GoogleAuthService {
  constructor({ store, verifyGoogle, now = () => new Date(), sessionTtl = 604800 }) {
    this.store = store; this.verifyGoogle = verifyGoogle; this.now = now; this.sessionTtl = sessionTtl;
  }
  async login(accessToken, ip = 'unknown', password) {
    if (typeof accessToken !== 'string' || !accessToken || accessToken.length > 16384) {
      throw new GoogleAuthError(401, 'invalid_google_token', 'Thiếu thông tin xác thực Google hợp lệ.');
    }
    await this.store.limit(`google-ip:${digest(ip)}`, 900, 30, this.now());
    const identity = await this.verifyGoogle(accessToken);
    if (!identity || typeof identity.id !== 'string' || !identity.id || identity.id.length > 128 ||
        !identity.email_confirmed_at || !Array.isArray(identity.identities) ||
        !identity.identities.some(item => item.provider === 'google')) {
      throw new GoogleAuthError(401, 'google_not_verified', 'Tài khoản Google chưa được xác minh.');
    }
    const email = typeof identity.email === 'string' ? identity.email.trim().toLowerCase() : '';
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new GoogleAuthError(401, 'invalid_google_email', 'Google chưa cung cấp email hợp lệ.');
    }
    await this.store.limit(`google-id:${digest(identity.id)}`, 900, 10, this.now());
    let user = await this.store.findByGoogleId(identity.id);
    let linkedExistingAccount = false;
    if (!user) {
      const existing = await this.store.findByEmail(email);
      if (existing) {
        user = await this.linkExistingAccount(existing, identity.id, email, password);
        linkedExistingAccount = true;
      } else {
        const metadata = identity.user_metadata ?? {};
        const nameValue = metadata.full_name ?? metadata.name;
        const name = typeof nameValue === 'string' ? nameValue.trim().slice(0, 100) : '';
        try {
          user = await this.store.createGoogleUser({ id: `c_${randomUUID()}`,
            email, emailNormalized: email, emailVerified: true,
            supabaseUserId: identity.id, googleId: identity.id, isGoogleLinked: true,
            name, phone: '', role: 'customer', isActive: true, identityActive: true,
            totalSpent: 0, totalOrders: 0, memberTier: 'Đồng', created_at: this.now().toISOString() });
        } catch (error) {
          if (error.code !== 11000) throw error;
          // Simultaneous OAuth callbacks must use the same canonical customer ID.
          user = await this.store.findByGoogleId(identity.id);
          if (!user) {
            const sameEmail = await this.store.findByEmail(email);
            if (!sameEmail) throw error;
            user = await this.linkExistingAccount(sameEmail, identity.id, email, password);
            linkedExistingAccount = true;
          }
        }
        }
    }
    if (user.isActive === false) throw new GoogleAuthError(403, 'account_locked', 'Tài khoản đã bị khóa. Vui lòng liên hệ hỗ trợ.');
    if (typeof user.id !== 'string' || !user.id) throw new GoogleAuthError(409, 'invalid_account', 'Tài khoản chưa có định danh hợp lệ.');
    const token = randomBytes(32).toString('base64url'), tokenHash = digest(token);
    const expiresAt = new Date(this.now().getTime() + this.sessionTtl * 1000);
    await this.store.putSession({ _id: tokenHash, userId: user.id,
      provider: 'google', expiresAt, createdAt: this.now() });
    const current = await this.store.findActiveGoogleUser(user.id, identity.id);
    if (!current) {
      await this.store.deleteSession(tokenHash);
      throw new GoogleAuthError(403, 'account_changed', 'Tài khoản đã thay đổi. Vui lòng đăng nhập lại.');
    }
    const name = typeof current.name === 'string' ? current.name : '';
    const phone = typeof current.phone === 'string' ? current.phone : '';
    return { token, expiresAt: expiresAt.toISOString(), linkedExistingAccount, customer: {
      id: current.id, email: current.email, name, phone, isActive: true, emailVerified: true,
      role: current.role === 'admin' ? 'admin' : 'customer', sessionProvider: 'google',
      profileCompleted: Boolean(name.trim() && phone.trim()),
      hasPassword: Boolean(current.password_hash ?? current.passwordHash ?? current.password),
      isGoogleLinked: true,
    } };
  }

  async linkExistingAccount(user, googleId, email, password) {
    if (user.isActive === false) throw new GoogleAuthError(403, 'account_locked', 'Tài khoản đã bị khóa.');
    if (user.role === 'admin') throw new GoogleAuthError(403, 'google_link_denied', 'Tài khoản quản trị cần đăng nhập bằng phương thức đã được cấp.');
    if (typeof user.id !== 'string' || !user.id) throw new GoogleAuthError(409, 'invalid_account', 'Tài khoản chưa có định danh hợp lệ.');
    if (user.supabaseUserId && user.supabaseUserId !== googleId) {
      throw new GoogleAuthError(409, 'google_already_linked', 'Tài khoản đã liên kết với một danh tính Google khác.');
    }
    const needsPassword = user.emailVerified !== true && user.supabaseUserId !== googleId;
    if (needsPassword) {
      if (typeof password !== 'string' || !password) {
        throw new GoogleAuthError(409, 'account_link_required', 'Nhập mật khẩu tài khoản email để xác nhận liên kết Google.');
      }
      await this.store.limit(`google-link:${digest(user.id)}`, 900, 5, this.now());
      if (!await verifyPassword(password, user)) {
        throw new GoogleAuthError(401, 'invalid_link_password', 'Mật khẩu tài khoản email không chính xác.');
      }
      if (!(user.password_hash ?? '').startsWith('scrypt$')) {
        const stored = user.password_hash ?? user.passwordHash ?? user.password;
        const migrationPassword = stored.startsWith('scrypt$') ? password : password.trim();
        user = await this.store.upgradePassword(user,
          await hashPassword(migrationPassword, { enforcePolicy: false }));
        if (!user) throw new GoogleAuthError(409, 'account_changed', 'Thông tin tài khoản đã thay đổi. Vui lòng đăng nhập lại.');
      }
    }
    const linked = await this.store.linkGoogle(user, googleId, email, needsPassword);
    if (!linked) throw new GoogleAuthError(409, 'account_changed', 'Thông tin tài khoản đã thay đổi. Vui lòng đăng nhập lại.');
    return linked;
  }
}
module.exports = { GoogleAuthService, GoogleAuthError };
