// Author: Chih An (GitHub: ChangChinAn)
// UC15: Lưu tin nhắn và đọc hội thoại hỗ trợ trong MongoDB.
class MongoSupportStore {
  constructor(db) { this.db = db; }
  async init() { await this.db.collection('chat_messages').createIndex({ conversationId: 1, createdAt: 1 }); }
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
