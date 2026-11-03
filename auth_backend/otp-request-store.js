// Author: Chih An (GitHub: ChangChinAn)
// UC01: Lưu yêu cầu gửi OTP và giới hạn gửi lại trong MongoDB.
const { OtpRequestError, digest } = require('./otp-request-service');

class MongoOtpRequestStore {
  constructor(db) { this.db = db; }
  async init() {
    for (const name of ['auth_challenges', 'otp_send_slots', 'otp_send_limits']) {
      await this.db.collection(name).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    }
  }
  async emailExists(email) {
    return Boolean(await this.findAccount(email));
  }
  async findAccount(email) {
    const escapedEmail = email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return this.db.collection('users').findOne({ $or: [
      { emailNormalized: email }, { email: { $regex: `^${escapedEmail}$`, $options: 'i' } },
    ] });
  }
  async limit(key, maximum, now) {
    const bucket = `${key}:${Math.floor(now.getTime() / 3600000)}`;
    const record = await this.db.collection('otp_send_limits').findOneAndUpdate({ _id: bucket },
      { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date(now.getTime() + 7200000) } },
      { upsert: true, returnDocument: 'after' });
    if (record.count > maximum) throw new OtpRequestError(429, 'Quá nhiều yêu cầu gửi OTP. Vui lòng thử lại sau.');
  }
  async claimSendSlot(email, now, seconds) {
    const slots = this.db.collection('otp_send_slots');
    const id = digest(email);
    try {
      await slots.findOneAndUpdate({ _id: id, nextAllowedAt: { $lte: now } },
        { $set: { nextAllowedAt: new Date(now.getTime() + seconds * 1000),
          expiresAt: new Date(now.getTime() + seconds * 2000) } }, { upsert: true });
    } catch (error) {
      if (error.code !== 11000) throw error;
      const current = await slots.findOne({ _id: id });
      const remaining = Math.max(1, Math.ceil((current.nextAllowedAt - now) / 1000));
      throw new OtpRequestError(429, `Vui lòng chờ ${remaining} giây trước khi gửi lại OTP.`, remaining);
    }
  }
  async putChallenge(challenge) { await this.db.collection('auth_challenges').insertOne(challenge); }
  async activateChallenge(id, email) {
    const challenges = this.db.collection('auth_challenges');
    await challenges.updateMany({ email, _id: { $ne: id }, state: { $in: ['sent', 'verified'] } },
      { $set: { state: 'expired' } });
    await challenges.updateOne({ _id: id }, { $set: { state: 'sent' } });
  }
  async removeChallenge(id) { await this.db.collection('auth_challenges').deleteOne({ _id: id }); }

  // UC02: Increment attempts atomically before comparing the OTP.
  async attemptOtp(id, now, maximum) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ _id: id,
      state: 'sent', expiresAt: { $gt: now },
      $or: [{ attempts: { $lt: maximum } }, { attempts: { $exists: false } }] },
    { $inc: { attempts: 1 } }, { returnDocument: 'after' });
  }
  async getChallenge(id) { return this.db.collection('auth_challenges').findOne({ _id: id }); }
  async verifyOtp(id, hash, proofHash, now, proofExpiresAt) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ _id: id,
      state: 'sent', otpHash: hash, expiresAt: { $gt: now } },
    { $set: { state: 'verified', proofHash, verifiedAt: now, expiresAt: proofExpiresAt },
      $unset: { otpHash: '' } }, { returnDocument: 'after' });
  }
}
module.exports = { MongoOtpRequestStore };
