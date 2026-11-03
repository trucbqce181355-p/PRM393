// Author: Chih An (GitHub: ChangChinAn)
// UC13–UC14: Quản lý và chọn địa chỉ giao hàng mặc định theo phiên đăng nhập.
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
function publicAddress(record, defaultId) {
  return { id: record._id, title: record.title, address: record.address, phone: record.phone,
    isDefault: record._id === defaultId };
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
    const savedId = await this.store.getDefaultId(session.customer.id);
    // Missing/deleted pointers fall back to the first remaining address.
    const defaultId = records.some(record => record._id === savedId) ? savedId : records[0]?._id;
    await this.sessions.restore(token);
    return { addresses: records.map(record => publicAddress(record, defaultId)) };
  }
  async selectDefault(token, id) {
    const session = await this.sessions.restore(token);
    this.validateId(id);
    if (!await this.store.selectDefault(session.customer.id, id)) {
      throw new AddressError(404, 'address_not_found', 'Địa chỉ không tồn tại hoặc không thuộc tài khoản.');
    }
    const current = await this.list(token);
    if (!current.addresses.some(address => address.id === id)) {
      throw new AddressError(404, 'address_not_found', 'Địa chỉ vừa bị xóa. Vui lòng tải lại danh sách.');
    }
    return current;
  }
  async create(token, input) {
    const session = await this.sessions.restore(token);
    const fields = validateAddress(input);
    const record = await this.store.create({ _id: `a_${randomUUID()}`, userId: session.customer.id,
      ...fields, createdAt: new Date().toISOString() });
    return { address: (await this.list(token)).addresses.find(address => address.id === record._id) ?? null };
  }
  async update(token, id, input) {
    const session = await this.sessions.restore(token);
    this.validateId(id);
    const record = await this.store.update(session.customer.id, id, validateAddress(input));
    if (!record) throw new AddressError(404, 'address_not_found', 'Địa chỉ không tồn tại hoặc đã bị xóa.');
    return { address: (await this.list(token)).addresses.find(address => address.id === record._id) ?? null };
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
