// Author: Chih An (GitHub: ChangChinAn)
// UC17–UC18: Đọc khách hàng, đổi trạng thái và thu hồi phiên tài khoản.
class MongoCustomerStore {
  constructor(db) { this.db = db; }
  async updateStatus(id, isActive) {
    const now = new Date();
    return this.db.collection('users').findOneAndUpdate({ id, role: { $ne: 'admin' },
      identityActive: { $ne: false }, mergedInto: { $exists: false } },
      { $set: { isActive, statusUpdatedAt: now.toISOString() }, $max: { sessionsInvalidBefore: now } },
      { returnDocument: 'after', projection: { _id: 0, id: 1, name: 1, email: 1, phone: 1,
        isActive: 1, created_at: 1, sessionsInvalidBefore: 1 } });
  }
  async revokeSessions(userId, cutoff) {
    await this.db.collection('auth_sessions').deleteMany({ userId,
      $or: [{ createdAt: { $lte: cutoff } }, { createdAt: null }] });
  }
  async list() {
    return this.db.collection('users').find({ role: { $ne: 'admin' },
      identityActive: { $ne: false }, mergedInto: { $exists: false }, id: { $type: 'string', $ne: '' } },
      { projection: { _id: 0, id: 1, name: 1, email: 1, phone: 1, isActive: 1, created_at: 1 } })
      .sort({ created_at: -1, id: 1 }).toArray();
  }
}
module.exports = { MongoCustomerStore };
