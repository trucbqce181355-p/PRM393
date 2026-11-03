// Author: Chih An (GitHub: ChangChinAn)
// UC17: Đọc danh sách khách hàng với danh sách trường công khai được phép trả về.
class MongoCustomerStore {
  constructor(db) { this.db = db; }
  async list() {
    return this.db.collection('users').find({ role: { $ne: 'admin' },
      identityActive: { $ne: false }, mergedInto: { $exists: false }, id: { $type: 'string', $ne: '' } },
      { projection: { _id: 0, id: 1, name: 1, email: 1, phone: 1, isActive: 1, created_at: 1 } })
      .sort({ created_at: -1, id: 1 }).toArray();
  }
}
module.exports = { MongoCustomerStore };
