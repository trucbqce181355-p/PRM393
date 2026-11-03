// Author: Chih An (GitHub: ChangChinAn)
// UC04: Cập nhật hash mật khẩu, tiêu thụ proof một lần và thu hồi phiên cũ.
const { PasswordResetError } = require('./password-reset-service');

class MongoPasswordResetStore {
  constructor(db) { this.db = db; }
  async claimProof(proofHash, now) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ proofHash,
      purpose: 'password_reset', state: 'verified', expiresAt: { $gt: now } },
    { $set: { state: 'resetting' } }, { returnDocument: 'after' });
  }
  async findAccount(id, email) {
    const escapedEmail = email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return this.db.collection('users').findOne({ id, $or: [
      { emailNormalized: email }, { email: { $regex: `^${escapedEmail}$`, $options: 'i' } },
    ] });
  }
  async updatePassword(id, hash, now) {
    const user = await this.db.collection('users').findOneAndUpdate({ id, isActive: { $ne: false } },
      { $set: { password_hash: hash, passwordChangedAt: now.toISOString() },
        $unset: { password: '', passwordHash: '' } }, { returnDocument: 'after' });
    if (!user) throw new PasswordResetError(403, 'account_locked', 'Tài khoản không còn khả dụng để đổi mật khẩu.');
  }
  async revokeSessions(userId) { await this.db.collection('auth_sessions').deleteMany({ userId }); }
  async consumeProof(proofHash) {
    await this.db.collection('auth_challenges').updateOne({ proofHash, state: 'resetting' },
      { $set: { state: 'consumed' } });
  }
  async releaseProof(proofHash) {
    await this.db.collection('auth_challenges').updateOne({ proofHash, state: 'resetting' },
      { $set: { state: 'verified' } });
  }
  async invalidateOtherResets(email, id) {
    await this.db.collection('auth_challenges').updateMany({ email, _id: { $ne: id },
      purpose: 'password_reset', state: { $in: ['sent', 'verified'] } },
    { $set: { state: 'expired' } });
  }
}
module.exports = { MongoPasswordResetStore };
