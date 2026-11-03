// Author: Chih An (GitHub: ChangChinAn)
// UC13: Thêm/xem/sửa/xóa địa chỉ của tài khoản được xác định từ phiên đăng nhập.
const { randomUUID } = require('node:crypto');
class AddressError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
function validateAddress(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input) ||
      Object.keys(input).some(key => !['title', 'address', 'phone'].includes(key))) {
    throw new AddressError(400, 'invalid_address', 'Thông tin địa chỉ không hợp lệ.');
  }
  const { title, address, phone } = input;
  if (typeof title !== 'string' || !title.trim() || title.trim().length > 100 ||
      typeof address !== 'string' || !address.trim() || address.trim().length > 500 ||
      typeof phone !== 'string' || !/^0\d{9}$/.test(phone.trim())) {
    throw new AddressError(400, 'invalid_address', 'Tên địa chỉ từ 1–100 ký tự, địa chỉ từ 1–500 ký tự; số điện thoại gồm 10 số và bắt đầu bằng 0.');
  }
  return { title: title.trim(), address: address.trim(), phone: phone.trim() };
}
function publicAddress(record) {
  return { id: record._id, title: record.title, address: record.address, phone: record.phone };
}
class AddressService {
  constructor({ sessions, store }) { this.sessions = sessions; this.store = store; }
  validateId(id) {
    if (typeof id !== 'string' || !/^a_[a-f0-9-]{36}$/.test(id)) {
      throw new AddressError(404, 'address_not_found', 'Địa chỉ không tồn tại.');
    }
  }
  async list(token) {
    const session = await this.sessions.restore(token);
    const records = await this.store.list(session.customer.id);
    await this.sessions.restore(token);
    return { addresses: records.map(publicAddress) };
  }
  async create(token, input) {
    const session = await this.sessions.restore(token);
    const fields = validateAddress(input);
    const record = await this.store.create({ _id: `a_${randomUUID()}`, userId: session.customer.id,
      ...fields, createdAt: new Date().toISOString() });
    return { address: publicAddress(record) };
  }
  async update(token, id, input) {
    const session = await this.sessions.restore(token);
    this.validateId(id);
    const record = await this.store.update(session.customer.id, id, validateAddress(input));
    if (!record) throw new AddressError(404, 'address_not_found', 'Địa chỉ không tồn tại hoặc đã bị xóa.');
    return { address: publicAddress(record) };
  }
  async delete(token, id) {
    const session = await this.sessions.restore(token);
    this.validateId(id);
    if (!await this.store.delete(session.customer.id, id)) {
      throw new AddressError(404, 'address_not_found', 'Địa chỉ không tồn tại hoặc đã bị xóa.');
    }
    return { deleted: true };
  }
}
module.exports = { AddressService, AddressError };
