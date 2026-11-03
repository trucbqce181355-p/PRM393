// Author: Chih An (GitHub: ChangChinAn)
// UC09: Đọc phiên còn hạn và tài khoản đang hoạt động từ MongoDB.
class MongoSessionStore {
  constructor(db) { this.db = db; }
  async findSession(hash, now) {
    return this.db.collection('auth_sessions').findOne({ _id: hash, expiresAt: { $gt: now } });
  }
  async findUser(id) {
    return this.db.collection('users').findOne({ id, identityActive: { $ne: false },
      mergedInto: { $exists: false } });
  }
}
module.exports = { MongoSessionStore };
