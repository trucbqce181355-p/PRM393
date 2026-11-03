// Author: Chih An (GitHub: ChangChinAn)
// UC11: Xem hồ sơ và hạng thành viên bằng danh tính từ phiên đã xác thực.
class ProfileService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
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
module.exports = { ProfileService };
