// Author: Chih An (GitHub: ChangChinAn)
// UC15–UC16: Hội thoại hỗ trợ và tạo/xem/sửa/hủy yêu cầu chưa xử lý.
const { randomUUID } = require('node:crypto');
class SupportError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class SupportService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
  async requestCustomer(token) {
    const { customer } = await this.sessions.restore(token);
    if (customer.role === 'admin') throw new SupportError(403, 'request_denied', 'Chức năng này dành cho tài khoản khách hàng.');
    return customer;
  }
  requestFields(body, allowed) {
    if (!body || typeof body !== 'object' || Array.isArray(body) ||
        Object.keys(body).some(key => !allowed.includes(key)) ||
        typeof body.reason !== 'string' || !body.reason.trim() || body.reason.length > 300 ||
        typeof body.description !== 'string' || !body.description.trim() || body.description.length > 4000) {
      throw new SupportError(400, 'invalid_request', 'Lý do từ 1–300 ký tự; nội dung từ 1–4.000 ký tự.');
    }
    return { reason: body.reason.trim(), description: body.description.trim() };
  }
  async requests(token) {
    const customer = await this.requestCustomer(token);
    const requests = await this.store.requests(customer.email);
    await this.requestCustomer(token);
    return { requests };
  }
  async createRequest(token, body) {
    const customer = await this.requestCustomer(token);
    const fields = this.requestFields(body, ['reason', 'description', 'orderId']);
    const orderId = body.orderId == null ? '' : body.orderId;
    if (typeof orderId !== 'string' || orderId.length > 100) {
      throw new SupportError(400, 'invalid_order', 'Mã đơn hàng không hợp lệ.');
    }
    if (orderId.trim() && !await this.store.ownsOrder(customer.email, orderId.trim())) {
      throw new SupportError(403, 'order_denied', 'Đơn hàng không thuộc tài khoản của bạn.');
    }
    const request = { id: `rr_${randomUUID()}`, customerEmail: customer.email, customerName: customer.name,
      orderId: orderId.trim(), ...fields, status: 'pending', adminReply: null, createdAt: new Date().toISOString() };
    await this.store.createRequest(request);
    return { request };
  }
  async changeRequest(token, id, body) {
    const customer = await this.requestCustomer(token);
    if (typeof id !== 'string' || !/^rr_[A-Za-z0-9_-]{1,80}$/.test(id)) {
      throw new SupportError(404, 'request_not_found', 'Không tìm thấy yêu cầu.');
    }
    let fields;
    if (body?.action === 'edit') {
      fields = this.requestFields(body, ['action', 'reason', 'description']);
    } else if (body?.action === 'cancel' && Object.keys(body).length === 1) {
      fields = { status: 'cancelled' };
    } else {
      throw new SupportError(400, 'invalid_request_action', 'Thao tác với yêu cầu không hợp lệ.');
    }
    const request = await this.store.changePendingRequest(customer.email, id, fields);
    if (!request) throw new SupportError(409, 'request_not_pending', 'Yêu cầu đã được xử lý, đã hủy hoặc không thuộc tài khoản. Vui lòng tải lại.');
    return { request };
  }
  async conversation(user, requested) {
    if (user.role !== 'admin') {
      if (requested != null && requested !== user.email) {
        throw new SupportError(403, 'conversation_denied', 'Không có quyền truy cập hội thoại này.');
      }
      return user.email;
    }
    const email = typeof requested === 'string' ? requested.trim().toLowerCase() : '';
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !await this.store.hasCustomer(email)) {
      throw new SupportError(404, 'conversation_not_found', 'Không tìm thấy tài khoản khách hàng của hội thoại.');
    }
    return email;
  }
  async snapshot(token, requested) {
    const { customer } = await this.sessions.restore(token);
    if (customer.role === 'admin' && requested == null) {
      const conversations = await this.store.conversations();
      const current = await this.sessions.restore(token);
      if (current.customer.role !== 'admin') {
        throw new SupportError(403, 'conversation_denied', 'Không có quyền xem danh sách hội thoại.');
      }
      return { conversations, messages: [] };
    }
    const conversationId = await this.conversation(customer, requested);
    const messages = await this.store.messages(conversationId);
    await this.sessions.restore(token);
    return { conversations: [], messages };
  }
  async send(token, body) {
    const { customer } = await this.sessions.restore(token);
    if (!body || typeof body !== 'object' || Array.isArray(body) ||
        Object.keys(body).some(key => !['message', 'conversationId'].includes(key)) ||
        typeof body.message !== 'string' || !body.message.trim() || body.message.length > 4000) {
      throw new SupportError(400, 'invalid_message', 'Nội dung hỗ trợ từ 1 đến 4.000 ký tự.');
    }
    const conversationId = await this.conversation(customer, body.conversationId);
    const message = { id: `msg_${randomUUID()}`, conversationId,
      senderEmail: customer.email, senderName: customer.name,
      senderRole: customer.role === 'admin' ? 'admin' : 'user',
      message: body.message.trim(), type: 'text', isRead: false, createdAt: new Date().toISOString() };
    await this.store.insert(message);
    return { message };
  }
}
module.exports = { SupportService, SupportError };
