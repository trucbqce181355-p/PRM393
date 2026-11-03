// Author: Chih An (GitHub: ChangChinAn)
// UC09: Xác thực token để khôi phục phiên, không gia hạn phiên đã hết hạn.
const { digest } = require('./otp-request-service');
class SessionError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class SessionService {
  constructor({ store, now = () => new Date() }) { this.store = store; this.now = now; }
  async restore(token) {
    if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) {
      throw new SessionError(401, 'session_expired', 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.');
    }
    const hash = digest(token);
    const session = await this.store.findSession(hash, this.now());
    if (!session || !['google', 'password'].includes(session.provider)) {
      throw new SessionError(401, 'session_expired', 'Phiên đăng nhập đã hết hạn hoặc bị thu hồi. Vui lòng đăng nhập lại.');
    }
    const user = await this.store.findUser(session.userId);
    if (!user || user.isActive === false) {
      throw new SessionError(403, 'account_unavailable', 'Tài khoản không còn khả dụng. Vui lòng đăng nhập lại.');
    }
    if (user.passwordChangedAt && (!session.createdAt || new Date(user.passwordChangedAt) > session.createdAt)) {
      throw new SessionError(401, 'session_expired', 'Mật khẩu đã thay đổi. Vui lòng đăng nhập lại.');
    }
    if (!await this.store.findSession(hash, this.now())) {
      throw new SessionError(401, 'session_expired', 'Phiên đăng nhập đã bị thu hồi. Vui lòng đăng nhập lại.');
    }
    const name = typeof user.name === 'string' ? user.name : '';
    const phone = typeof user.phone === 'string' ? user.phone : '';
    return { token, expiresAt: session.expiresAt.toISOString(), customer: {
      id: user.id, email: user.email, name, phone,
      role: user.role === 'admin' ? 'admin' : 'customer',
      profileCompleted: Boolean(name.trim() && phone.trim()),
      hasPassword: Boolean(user.password_hash ?? user.passwordHash ?? user.password),
      sessionProvider: session.provider,
    } };
  }
}
module.exports = { SessionService, SessionError };
