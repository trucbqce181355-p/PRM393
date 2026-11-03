// Author: Chih An (GitHub: ChangChinAn)
// UC08: Hoàn tất hồ sơ tài khoản Google bằng phiên đăng nhập của ứng dụng.
const { digest } = require('./otp-request-service');
const { validatePassword, hashPassword } = require('./password-security');

class GoogleProfileError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class GoogleProfileService {
  constructor({ store, now = () => new Date() }) { this.store = store; this.now = now; }
  async complete(token, { name, phone, password } = {}) {
    if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) {
      throw new GoogleProfileError(401, 'session_expired', 'Vui lòng đăng nhập Google lại.');
    }
    const tokenHash = digest(token);
    const session = await this.store.findSession(tokenHash, this.now());
    if (!session) throw new GoogleProfileError(401, 'session_expired', 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập Google lại.');
    const user = await this.store.findGoogleUser(session.userId);
    if (!user) throw new GoogleProfileError(403, 'account_unavailable', 'Tài khoản không khả dụng. Vui lòng đăng nhập lại.');
    if (user.name?.trim() && user.phone?.trim()) {
      throw new GoogleProfileError(409, 'profile_completed', 'Hồ sơ đã được hoàn tất. Vui lòng đăng nhập lại để cập nhật thông tin.');
    }
    if (typeof name !== 'string' || !name.trim() || name.trim().length > 100 ||
        typeof phone !== 'string' || !/^0\d{9}$/.test(phone.trim())) {
      throw new GoogleProfileError(400, 'invalid_profile', 'Họ tên hoặc số điện thoại không hợp lệ.');
    }
    const hasPassword = Boolean(user.password_hash ?? user.passwordHash ?? user.password);
    const fields = { name: name.trim(), phone: phone.trim(), profileCompletedAt: this.now().toISOString() };
    if (!hasPassword) {
      validatePassword(password);
      fields.password_hash = await hashPassword(password);
    } else if (password != null && password !== '') {
      throw new GoogleProfileError(409, 'password_exists', 'Tài khoản đã có mật khẩu. Không đổi mật khẩu ở bước hồ sơ.');
    }
    if (!await this.store.findSession(tokenHash, this.now())) {
      throw new GoogleProfileError(401, 'session_expired', 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    const updated = await this.store.completeProfile(user, fields);
    if (!updated) throw new GoogleProfileError(409, 'account_changed', 'Thông tin tài khoản đã thay đổi. Vui lòng đăng nhập lại.');
    return { token, expiresAt: session.expiresAt.toISOString(), customer: {
      id: updated.id, name: updated.name, email: updated.email, phone: updated.phone,
      role: 'customer', profileCompleted: true, hasPassword: true, sessionProvider: 'google',
    } };
  }
}
module.exports = { GoogleProfileService, GoogleProfileError };
