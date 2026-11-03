// Author: Chih An (GitHub: ChangChinAn)
// UC03: Tiêu thụ bằng chứng xác minh email và lưu tài khoản MongoDB.
const { RegistrationError } = require('./registration-service');

class MongoRegistrationStore {
  constructor(db) { this.db = db; }
  async init() {
    await this.db.collection('users').createIndex({ emailNormalized: 1 }, {
      unique: true, partialFilterExpression: { emailNormalized: { $type: 'string' } },
      name: 'registration_email_unique',
    });
  }
  async claimProof(proofHash, now) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ proofHash,
      state: 'verified', purpose: 'registration', expiresAt: { $gt: now } },
    { $set: { state: 'registering' } }, { returnDocument: 'after' });
  }
  async consumeProof(proofHash) {
    await this.db.collection('auth_challenges').updateOne({ proofHash, state: 'registering' },
      { $set: { state: 'consumed' } });
  }
  async releaseProof(proofHash) {
    await this.db.collection('auth_challenges').updateOne({ proofHash, state: 'registering' },
      { $set: { state: 'verified' } });
  }
  async createUser(user) {
    const users = this.db.collection('users');
    const escapedEmail = user.email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const duplicate = await users.findOne({ $or: [
      { emailNormalized: user.emailNormalized },
      { email: { $regex: `^${escapedEmail}$`, $options: 'i' } },
    ] });
    if (duplicate) throw new RegistrationError(409, 'email_exists', 'Email này đã có tài khoản.');
    try {
      await users.insertOne(user);
      return user;
    } catch (error) {
      if (error.code === 11000) throw new RegistrationError(409, 'email_exists', 'Email này đã có tài khoản.');
      throw error;
    }
  }
}
module.exports = { MongoRegistrationStore };
