// Author: Chih An (GitHub: ChangChinAn)
// UC11–UC12: Xem và chỉnh sửa hồ sơ bằng danh tính từ phiên đã xác thực.
class ProfileError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class ProfileService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
  async update(token, input = {}) {
    const authenticated = await this.sessions.restore(token);
    if (!input || typeof input !== 'object' || Array.isArray(input) ||
        Object.keys(input).some(key => !['name', 'phone'].includes(key))) {
      throw new ProfileError(400, 'invalid_profile', 'Chỉ được cập nhật họ tên và số điện thoại.');
    }
    const { name, phone } = input;
    if (typeof name !== 'string' || !name.trim() || name.trim().length > 100 ||
        typeof phone !== 'string' || !/^0\d{9}$/.test(phone.trim())) {
      throw new ProfileError(400, 'invalid_profile', 'Họ tên từ 1 đến 100 ký tự; số điện thoại gồm 10 số và bắt đầu bằng 0.');
    }
    const updated = await this.store.updateProfile(authenticated.customer.id,
      { name: name.trim(), phone: phone.trim() });
    if (!updated) throw new ProfileError(403, 'account_unavailable', 'Tài khoản không còn khả dụng. Vui lòng đăng nhập lại.');
    return this.view(token);
  }
  async view(token) {
    const authenticated = await this.sessions.restore(token);
    const membership = await this.store.membership(authenticated.customer.email);
    // Recheck revocation/account status after the membership query.
    const current = await this.sessions.restore(token);
    const customer = current.customer;
    return { id: customer.id, name: customer.name, email: customer.email, phone: customer.phone,
      role: customer.role, totalSpent: membership.totalSpent, totalOrders: membership.totalOrders,
      memberTier: membership.totalSpent >= 2000000 ? 'Vàng' : membership.totalSpent >= 500000 ? 'Bạc' : 'Đồng' };
  }
}
module.exports = { ProfileService, ProfileError };
