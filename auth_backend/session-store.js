// Author: Chih An (GitHub: ChangChinAn)
// UC09–UC10: Đọc phiên còn hạn và xóa phiên theo hash token khi đăng xuất.
class MongoSessionStore {
  constructor(db) { this.db = db; }
  async deleteSession(hash) {
    await this.db.collection('auth_sessions').deleteOne({ _id: hash });
  }
  async findSession(hash, now) {
    return this.db.collection('auth_sessions').findOne({ _id: hash, expiresAt: { $gt: now } });
  }
  async findUser(id) {
    return this.db.collection('users').findOne({ id, identityActive: { $ne: false },
      mergedInto: { $exists: false } });
  }
}
module.exports = { MongoSessionStore };
