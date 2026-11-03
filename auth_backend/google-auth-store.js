// Author: Chih An (GitHub: ChangChinAn)
// UC06–UC07: Tra cứu và liên kết Google trên đúng tài khoản email hiện có.
const { MongoLoginStore } = require('./login-store');
const { GoogleAuthError } = require('./google-auth-service');

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
  async linkGoogle(user, googleId, email, requirePasswordMatch) {
    const escapedEmail = email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const filter = { id: user.id, isActive: { $ne: false }, identityActive: { $ne: false },
      mergedInto: { $exists: false }, role: { $ne: 'admin' }, $and: [
        { $or: [{ supabaseUserId: { $exists: false } }, { supabaseUserId: null },
          { supabaseUserId: '' }, { supabaseUserId: googleId }] },
        { $or: [{ emailNormalized: email }, { email: { $regex: `^${escapedEmail}$`, $options: 'i' } }] },
      ] };
    if (requirePasswordMatch) {
      const field = user.password_hash != null ? 'password_hash' : user.passwordHash != null ? 'passwordHash' : 'password';
      filter[field] = user[field];
    } else {
      filter.$and.push({ $or: [{ emailVerified: true }, { supabaseUserId: googleId }] });
    }
    try {
      return await this.db.collection('users').findOneAndUpdate(filter,
        { $set: { supabaseUserId: googleId, googleId, isGoogleLinked: true,
          emailVerified: true, googleLinkedAt: new Date().toISOString() } },
        { returnDocument: 'after' });
    } catch (error) {
      if (error.code === 11000) throw new GoogleAuthError(409, 'google_already_linked', 'Danh tính Google đã liên kết với tài khoản khác.');
      throw error;
    }
  }
}
module.exports = { MongoGoogleAuthStore };
