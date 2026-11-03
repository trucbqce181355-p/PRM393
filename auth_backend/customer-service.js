// Author: Chih An (GitHub: ChangChinAn)
// UC17–UC18: Phân quyền xem khách hàng và khóa/mở khóa tài khoản khách hàng.
class CustomerError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
function publicCustomer(user) {
  return { id: user.id, name: typeof user.name === 'string' ? user.name : '',
    email: typeof user.email === 'string' ? user.email : '', phone: typeof user.phone === 'string' ? user.phone : '',
    isActive: user.isActive !== false, createdAt: typeof user.created_at === 'string' ? user.created_at : null };
}
class CustomerService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
  async requireAdmin(token) {
    const session = await this.sessions.restore(token);
    if (session.customer.role !== 'admin') {
      throw new CustomerError(403, 'admin_required', 'Chỉ quản trị viên được quản lý khách hàng.');
    }
    return session.customer;
  }
  async changeStatus(token, id, body) {
    const admin = await this.requireAdmin(token);
    if (typeof id !== 'string' || !id || id.length > 128 || id === admin.id) {
      throw new CustomerError(400, 'invalid_customer', 'Chỉ thay đổi trạng thái tài khoản khách hàng.');
    }
    if (!body || typeof body !== 'object' || Array.isArray(body) ||
        Object.keys(body).length !== 1 || typeof body.isActive !== 'boolean') {
      throw new CustomerError(400, 'invalid_status', 'Trạng thái tài khoản không hợp lệ.');
    }
    const updated = await this.store.updateStatus(id, body.isActive);
    if (!updated) throw new CustomerError(404, 'customer_not_found', 'Không tìm thấy tài khoản khách hàng.');
    // Revoke on both actions: unlocking never reactivates an old session.
    await this.store.revokeSessions(id, updated.sessionsInvalidBefore);
    await this.requireAdmin(token);
    return { customer: publicCustomer(updated) };
  }
  async list(token) {
    await this.requireAdmin(token);
    const users = await this.store.list();
    await this.requireAdmin(token);
    return { customers: users.map(publicCustomer) };
  }
}
module.exports = { CustomerService, CustomerError };
