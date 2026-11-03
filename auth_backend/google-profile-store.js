// Author: Chih An (GitHub: ChangChinAn)
// UC08: Tra cứu phiên Google và lưu thông tin hoàn tất hồ sơ vào MongoDB.
class MongoGoogleProfileStore {
  constructor(db) { this.db = db; }
  async findSession(hash, now) {
    return this.db.collection('auth_sessions').findOne({ _id: hash, provider: 'google', expiresAt: { $gt: now } });
  }
  async findGoogleUser(id) {
    return this.db.collection('users').findOne({ id, role: { $ne: 'admin' },
      supabaseUserId: { $type: 'string', $ne: '' }, isActive: { $ne: false },
      identityActive: { $ne: false }, mergedInto: { $exists: false } });
  }
  async completeProfile(user, fields) {
    const filter = { id: user.id, supabaseUserId: user.supabaseUserId,
      isActive: { $ne: false }, identityActive: { $ne: false },
      mergedInto: { $exists: false }, role: { $ne: 'admin' } };
    // Match the read values so concurrent profile/password updates are preserved.
    for (const field of ['name', 'phone', 'password_hash', 'passwordHash', 'password']) {
      filter[field] = user[field] === undefined ? { $exists: false } : user[field];
    }
    return this.db.collection('users').findOneAndUpdate(filter,
      { $set: fields }, { returnDocument: 'after' });
  }
}
module.exports = { MongoGoogleProfileStore };
