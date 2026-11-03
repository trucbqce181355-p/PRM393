// Author: Chih An (GitHub: ChangChinAn)
// UC06: Xác minh danh tính Google và cấp token đăng nhập của ứng dụng.
const { randomBytes, randomUUID } = require('node:crypto');
const { digest } = require('./otp-request-service');

class GoogleAuthError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class GoogleAuthService {
  constructor({ store, verifyGoogle, now = () => new Date(), sessionTtl = 604800 }) {
    this.store = store; this.verifyGoogle = verifyGoogle; this.now = now; this.sessionTtl = sessionTtl;
  }
  async login(accessToken, ip = 'unknown') {
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
    if (!user) {
      if (await this.store.findByEmail(email)) {
        throw new GoogleAuthError(409, 'account_link_required', 'Email này đã có tài khoản. Vui lòng sử dụng đăng nhập bằng email/mật khẩu.');
      }
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
        if (!user) throw new GoogleAuthError(409, 'account_link_required', 'Email này đã có tài khoản. Vui lòng sử dụng đăng nhập bằng email/mật khẩu.');
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
    return { token, expiresAt: expiresAt.toISOString(), customer: {
      id: current.id, email: current.email, name, phone, isActive: true, emailVerified: true,
      role: current.role === 'admin' ? 'admin' : 'customer', sessionProvider: 'google',
      profileCompleted: Boolean(name.trim() && phone.trim()),
      hasPassword: Boolean(current.password_hash ?? current.passwordHash ?? current.password),
    } };
  }
}
module.exports = { GoogleAuthService, GoogleAuthError };
