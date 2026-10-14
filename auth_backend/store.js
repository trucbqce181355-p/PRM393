const { AuthError } = require('./security');

async function initializeStore(db) {
  for (const collection of ['auth_challenges', 'auth_limits']) {
    await db.collection(collection).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  }
}

class MongoStore {
  constructor(db) { this.db = db; }
  findEmail(email) {
    // Legacy users may not have emailNormalized until the account migration step.
    const escaped = email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return this.db.collection('users').findOne({ mergedInto: { $exists: false },
      $or: [{ emailNormalized: email }, { email: { $regex: `^\\s*${escaped}\\s*$`, $options: 'i' } }] });
  }
  async limit(key, seconds, maximum, now) {
    const bucket = `${key}:${Math.floor(now.getTime() / (seconds * 1000))}`;
    const record = await this.db.collection('auth_limits').findOneAndUpdate({ _id: bucket },
      { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date(now.getTime() + seconds * 2000) } },
      { upsert: true, returnDocument: 'after' });
    if (record.count > maximum) throw new AuthError(429, 'Quá nhiều yêu cầu. Vui lòng thử lại sau.');
  }
  async cooldown(key, seconds, now) {
    try {
      await this.db.collection('auth_limits').findOneAndUpdate({ _id: key,
        nextAllowedAt: { $lte: now } }, { $set: {
          nextAllowedAt: new Date(now.getTime() + seconds * 1000),
          expiresAt: new Date(now.getTime() + seconds * 2000),
        } }, { upsert: true });
    } catch (error) {
      if (error.code === 11000) throw new AuthError(429, `Vui lòng chờ ${seconds} giây trước khi gửi lại OTP.`);
      throw error;
    }
  }
  async putChallenge(challenge) { await this.db.collection('auth_challenges').insertOne(challenge); }
  async activateChallenge(id) {
    const current = await this.db.collection('auth_challenges').findOne({ _id: id });
    await this.db.collection('auth_challenges').updateMany({ email: current.email,
      _id: { $ne: id }, state: { $in: ['sent', 'verified'] } }, { $set: { state: 'expired' } });
    await this.db.collection('auth_challenges').updateOne({ _id: id }, { $set: { state: 'sent' } });
  }
  async removeChallenge(id) { await this.db.collection('auth_challenges').deleteOne({ _id: id }); }
}
module.exports = { MongoStore, initializeStore };
