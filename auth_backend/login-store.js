// Author: Chih An (GitHub: ChangChinAn)
// UC05: Tra cứu tài khoản và lưu token đăng nhập dạng hash trong MongoDB.
const { LoginError } = require('./login-service');

class MongoLoginStore {
  constructor(db) { this.db = db; }
  async init() {
    for (const name of ['auth_sessions', 'auth_limits']) {
      await this.db.collection(name).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    }
  }
  async findByEmail(email) {
    const escapedEmail = email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return this.db.collection('users').findOne({ identityActive: { $ne: false }, mergedInto: { $exists: false },
      $or: [{ emailNormalized: email }, { email: { $regex: `^${escapedEmail}$`, $options: 'i' } }] });
  }
  async limit(key, seconds, maximum, now) {
    const bucket = `${key}:${Math.floor(now.getTime() / (seconds * 1000))}`;
    const record = await this.db.collection('auth_limits').findOneAndUpdate({ _id: bucket },
      { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date(now.getTime() + seconds * 2000) } },
      { upsert: true, returnDocument: 'after' });
    if (record.count > maximum) throw new LoginError(429, 'login_rate_limit', 'Quá nhiều lần đăng nhập. Vui lòng thử lại sau 15 phút.');
  }
  async upgradePassword(user, hash) {
    const field = user.password_hash != null ? 'password_hash' : user.passwordHash != null ? 'passwordHash' : 'password';
    return this.db.collection('users').findOneAndUpdate({ id: user.id,
      isActive: { $ne: false }, [field]: user[field] },
    { $set: { password_hash: hash }, $unset: { password: '', passwordHash: '' } },
    { returnDocument: 'after' });
  }
  async findActiveWithPassword(id, passwordHash) {
    return this.db.collection('users').findOne({ id, password_hash: passwordHash,
      isActive: { $ne: false }, identityActive: { $ne: false }, mergedInto: { $exists: false } });
  }
  async putSession(session) { await this.db.collection('auth_sessions').insertOne(session); }
  async deleteSession(hash) { await this.db.collection('auth_sessions').deleteOne({ _id: hash }); }
}
module.exports = { MongoLoginStore };
