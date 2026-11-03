// Author: Chih An (GitHub: ChangChinAn)
// UC15: Gửi tin nhắn/yêu cầu hỗ trợ và xem phản hồi theo quyền của phiên đăng nhập.
const { randomUUID } = require('node:crypto');
class SupportError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class SupportService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
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
