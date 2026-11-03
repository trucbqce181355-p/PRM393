// Author: Chih An (GitHub: ChangChinAn)
// UC05: Đăng nhập bằng email/mật khẩu, kiểm tra tài khoản và cấp token.
const { randomBytes } = require('node:crypto');
const { digest } = require('./otp-request-service');
const { verifyPassword, hashPassword } = require('./password-security');

class LoginError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class LoginService {
  constructor({ store, now = () => new Date(), sessionTtl = 604800 }) {
    this.store = store; this.now = now; this.sessionTtl = sessionTtl;
  }

  async login({ email: emailValue, password } = {}, ip = 'unknown') {
    if (typeof emailValue !== 'string' || typeof password !== 'string' || !password || password.length > 256) {
      throw new LoginError(400, 'invalid_input', 'Vui lòng nhập email và mật khẩu hợp lệ.');
    }
    const email = emailValue.trim().toLowerCase();
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new LoginError(400, 'invalid_input', 'Địa chỉ email không hợp lệ.');
    }
    const now = this.now();
    await this.store.limit(`login-ip:${digest(ip)}`, 900, 50, now);
    await this.store.limit(`login-email:${digest(email)}`, 900, 10, now);
    let user = await this.store.findByEmail(email);
    if (!user || !await verifyPassword(password, user)) {
      throw new LoginError(401, 'invalid_credentials', 'Email hoặc mật khẩu không chính xác.');
    }
    if (user.isActive === false) throw new LoginError(403, 'account_locked', 'Tài khoản đã bị khóa. Vui lòng liên hệ hỗ trợ.');
    if (typeof user.id !== 'string' || !user.id) throw new LoginError(409, 'invalid_account', 'Tài khoản chưa có định danh hợp lệ. Vui lòng liên hệ hỗ trợ.');
    if (!(user.password_hash ?? '').startsWith('scrypt$')) {
      const stored = user.password_hash ?? user.passwordHash ?? user.password;
      const migrationPassword = stored.startsWith('scrypt$') ? password : password.trim();
      const hash = await hashPassword(migrationPassword, { enforcePolicy: false });
      user = await this.store.upgradePassword(user, hash);
      if (!user) throw new LoginError(401, 'credentials_changed', 'Thông tin tài khoản đã thay đổi. Vui lòng đăng nhập lại.');
    }
    const token = randomBytes(32).toString('base64url');
    const tokenHash = digest(token);
    const expiresAt = new Date(this.now().getTime() + this.sessionTtl * 1000);
    await this.store.putSession({ _id: tokenHash, userId: user.id,
      provider: 'password', expiresAt, createdAt: this.now() });
    // Prevent a concurrent password reset/account lock from leaving an old-credential login valid.
    const current = await this.store.findActiveWithPassword(user.id, user.password_hash);
    if (!current) {
      await this.store.deleteSession(tokenHash);
      throw new LoginError(401, 'credentials_changed', 'Thông tin tài khoản đã thay đổi. Vui lòng đăng nhập lại.');
    }
    return { token, expiresAt: expiresAt.toISOString(), customer: {
      id: current.id, name: current.name ?? '', email: current.email,
      phone: current.phone ?? '', role: current.role === 'admin' ? 'admin' : 'customer',
      isActive: true, emailVerified: current.emailVerified === true,
    } };
  }
}
module.exports = { LoginService, LoginError };
