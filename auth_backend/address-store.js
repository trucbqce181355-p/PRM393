// Author: Chih An (GitHub: ChangChinAn)
// UC13: Lưu và truy vấn địa chỉ theo chủ sở hữu trong MongoDB.
class MongoAddressStore {
  constructor(db) { this.db = db; }
  async init() { await this.db.collection('customer_addresses').createIndex({ userId: 1, createdAt: 1 }); }
  async list(userId) {
    return this.db.collection('customer_addresses').find({ userId }).sort({ createdAt: 1, _id: 1 }).toArray();
  }
  async create(record) { await this.db.collection('customer_addresses').insertOne(record); return record; }
  async update(userId, id, fields) {
    return this.db.collection('customer_addresses').findOneAndUpdate({ _id: id, userId },
      { $set: { ...fields, updatedAt: new Date().toISOString() } }, { returnDocument: 'after' });
  }
  async delete(userId, id) {
    return (await this.db.collection('customer_addresses').deleteOne({ _id: id, userId })).deletedCount === 1;
  }
}
module.exports = { MongoAddressStore };
