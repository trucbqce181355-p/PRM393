// Author: Chih An (GitHub: ChangChinAn)
// UC17: Chỉ quản trị viên được xem danh sách khách hàng.
class CustomerError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class CustomerService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
  async requireAdmin(token) {
    const session = await this.sessions.restore(token);
    if (session.customer.role !== 'admin') {
      throw new CustomerError(403, 'admin_required', 'Chỉ quản trị viên được xem danh sách khách hàng.');
    }
  }
  async list(token) {
    await this.requireAdmin(token);
    const users = await this.store.list();
    await this.requireAdmin(token);
    return { customers: users.map(user => ({ id: user.id,
      name: typeof user.name === 'string' ? user.name : '',
      email: typeof user.email === 'string' ? user.email : '',
      phone: typeof user.phone === 'string' ? user.phone : '',
      isActive: user.isActive !== false,
      createdAt: typeof user.created_at === 'string' ? user.created_at : null,
    })) };
  }
}
module.exports = { CustomerService, CustomerError };
