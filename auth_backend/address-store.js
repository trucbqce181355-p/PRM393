// Author: Chih An (GitHub: ChangChinAn)
// UC13–UC14: Quản lý địa chỉ và lưu một địa chỉ mặc định trên mỗi tài khoản.
class MongoAddressStore {
  constructor(db) { this.db = db; }
  async init() { await this.db.collection('customer_addresses').createIndex({ userId: 1, createdAt: 1 }); }
  async list(userId) {
    return this.db.collection('customer_addresses').find({ userId }).sort({ createdAt: 1, _id: 1 }).toArray();
  }
  async create(record) { await this.db.collection('customer_addresses').insertOne(record); return record; }
  async getDefaultId(userId) {
    const user = await this.db.collection('users').findOne({ id: userId }, { projection: { defaultAddressId: 1 } });
    return user?.defaultAddressId ?? null;
  }
  async selectDefault(userId, id) {
    const owned = await this.db.collection('customer_addresses').findOne({ _id: id, userId });
    if (!owned) return false;
    // A single pointer makes concurrent selections replace one another atomically.
    const result = await this.db.collection('users').updateOne({ id: userId,
      isActive: { $ne: false }, identityActive: { $ne: false }, mergedInto: { $exists: false } },
      { $set: { defaultAddressId: id } });
    return result.matchedCount === 1;
  }
  async update(userId, id, fields) {
    return this.db.collection('customer_addresses').findOneAndUpdate({ _id: id, userId },
      { $set: { ...fields, updatedAt: new Date().toISOString() } }, { returnDocument: 'after' });
  }
  async delete(userId, id) {
    const deleted = (await this.db.collection('customer_addresses').deleteOne({ _id: id, userId })).deletedCount === 1;
    if (deleted) {
      await this.db.collection('users').updateOne({ id: userId, defaultAddressId: id },
        { $unset: { defaultAddressId: '' } });
    }
    return deleted;
  }
}
module.exports = { MongoAddressStore };
