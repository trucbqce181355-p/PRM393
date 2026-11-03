// Author: Chih An (GitHub: ChangChinAn)
// UC06: Lưu danh tính Google và tra cứu tài khoản Google trong MongoDB.
const { MongoLoginStore } = require('./login-store');

class MongoGoogleAuthStore extends MongoLoginStore {
  async init() {
    await super.init();
    await this.db.collection('users').createIndex({ supabaseUserId: 1 }, {
      unique: true, partialFilterExpression: { supabaseUserId: { $type: 'string' }, identityActive: true },
      name: 'auth_supabase_uid_unique',
    });
  }
  async findByGoogleId(id) {
    return this.db.collection('users').findOne({ supabaseUserId: id,
      identityActive: { $ne: false }, mergedInto: { $exists: false } });
  }
  async createGoogleUser(user) {
    await this.db.collection('users').insertOne(user);
    return user;
  }
  async findActiveGoogleUser(id, googleId) {
    return this.db.collection('users').findOne({ id, supabaseUserId: googleId,
      isActive: { $ne: false }, identityActive: { $ne: false }, mergedInto: { $exists: false } });
  }
}
module.exports = { MongoGoogleAuthStore };
