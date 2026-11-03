// Author: Chih An (GitHub: ChangChinAn)
// UC15–UC16: Lưu hội thoại và quản lý yêu cầu hỗ trợ chưa được xử lý.
class MongoSupportStore {
  constructor(db) { this.db = db; }
  async init() {
    await this.db.collection('chat_messages').createIndex({ conversationId: 1, createdAt: 1 });
    await this.db.collection('return_requests').createIndex({ customerEmail: 1, createdAt: -1 });
  }
  async requests(email) {
    return this.db.collection('return_requests').find({ customerEmail: email }, { projection: { _id: 0 } })
      .sort({ createdAt: -1, id: 1 }).toArray();
  }
  async ownsOrder(email, id) {
    return Boolean(await this.db.collection('orders').findOne({ id, customerEmail: email }, { projection: { _id: 1 } }));
  }
  async createRequest(request) { await this.db.collection('return_requests').insertOne({ ...request }); }
  async changePendingRequest(email, id, fields) {
    const record = await this.db.collection('return_requests').findOneAndUpdate(
      { id, customerEmail: email, status: 'pending' },
      { $set: { ...fields, updatedAt: new Date().toISOString() } }, { returnDocument: 'after' });
    if (record) delete record._id;
    return record;
  }
  async messages(conversationId) {
    return this.db.collection('chat_messages').find({ conversationId }, { projection: { _id: 0 } })
      .sort({ createdAt: 1, id: 1 }).toArray();
  }
  async conversations() {
    return this.db.collection('chat_messages').aggregate([
      { $sort: { createdAt: 1, id: 1 } },
      { $group: { _id: '$conversationId', lastMessage: { $last: '$message' }, updatedAt: { $last: '$createdAt' } } },
      { $sort: { updatedAt: -1, _id: 1 } },
      { $project: { _id: 0, conversationId: '$_id', lastMessage: 1, updatedAt: 1 } },
    ]).toArray();
  }
  async hasCustomer(email) {
    return Boolean(await this.db.collection('users').findOne({
      $or: [{ emailNormalized: email }, { email }], role: { $ne: 'admin' },
      identityActive: { $ne: false }, mergedInto: { $exists: false } }, { projection: { _id: 1 } }));
  }
  async insert(message) { await this.db.collection('chat_messages').insertOne({ ...message }); }
}
module.exports = { MongoSupportStore };
