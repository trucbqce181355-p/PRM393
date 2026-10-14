const { AuthError, normalizeEmail } = require('./security');

async function inspectUsers(db) {
  const users = await db.collection('users').find({ mergedInto: { $exists: false } }).toArray();
  const byEmail = new Map(), byId = new Map(), invalid = [];
  for (const user of users) {
    let email;
    try { email = normalizeEmail(user.email); } catch { invalid.push(String(user._id)); continue; }
    if (!user.id || typeof user.id !== 'string') { invalid.push(String(user._id)); continue; }
    byEmail.set(email, [...(byEmail.get(email) ?? []), user]);
    byId.set(user.id, [...(byId.get(user.id) ?? []), user]);
  }
  const conflicts = [...byEmail.entries()].filter(([, values]) => values.length > 1)
    .map(([email, values]) => ({ email, records: values.map(u => ({ mongoId: String(u._id), id: u.id })) }));
  const duplicateIds = [...byId.entries()].filter(([, values]) => values.length > 1).map(([id]) => id);
  return { users, conflicts, duplicateIds, invalid };
}

async function initializeStore(db) {
  const report = await inspectUsers(db);
  if (report.conflicts.length || report.duplicateIds.length || report.invalid.length) {
    throw new Error('Dữ liệu users có email/ID trùng hoặc không hợp lệ. Chạy npm run check-users trước khi khởi động; không tự gộp dữ liệu.');
  }
  // Never change the existing business ID or order references.
  for (const user of report.users) {
    await db.collection('users').updateOne({ _id: user._id }, {
      $set: { emailNormalized: normalizeEmail(user.email), identityActive: true },
    });
  }
  await db.collection('users').createIndex({ emailNormalized: 1 }, {
    unique: true, partialFilterExpression: { identityActive: true }, name: 'auth_email_unique',
  });
  await db.collection('users').createIndex({ id: 1 }, {
    unique: true, partialFilterExpression: { identityActive: true }, name: 'auth_id_unique',
  });
  await db.collection('users').createIndex({ supabaseUserId: 1 }, {
    unique: true, partialFilterExpression: { supabaseUserId: { $type: 'string' }, identityActive: true },
    name: 'auth_supabase_uid_unique',
  });
  for (const collection of ['auth_sessions', 'auth_challenges', 'auth_limits']) {
    await db.collection(collection).createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  }
}

class MongoStore {
  constructor(db) { this.db = db; }
  users() { return this.db.collection('users'); }
  findEmail(email) { return this.users().findOne({ emailNormalized: email, identityActive: true }); }
  findGoogle(uid) { return this.users().findOne({ supabaseUserId: uid, identityActive: true }); }
  findId(id) { return this.users().findOne({ id, identityActive: true }); }
  async upgradePassword(id, hash) {
    await this.users().updateOne({ id, identityActive: true }, {
      $set: { password_hash: hash }, $unset: { password: '', passwordHash: '' },
    });
  }
  async createUser(user) {
    try { await this.users().insertOne(user); return user; }
    catch (error) { if (error.code === 11000) throw new AuthError(409, 'Email đã được đăng ký. Vui lòng đăng nhập.'); throw error; }
  }
  async linkGoogle(id, uid) {
    try {
      const user = await this.users().findOneAndUpdate({ id, identityActive: true,
        $or: [{ supabaseUserId: { $exists: false } }, { supabaseUserId: uid }] },
      { $set: { supabaseUserId: uid, emailVerified: true } }, { returnDocument: 'after' });
      if (!user) throw new AuthError(409, 'Tài khoản đã liên kết với danh tính Google khác.');
      return user;
    } catch (error) {
      if (error.code === 11000) throw new AuthError(409, 'Danh tính Google đã được liên kết.');
      throw error;
    }
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
  async attemptChallenge(id, now, maxAttempts) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ _id: id, state: 'sent',
      expiresAt: { $gt: now }, attempts: { $lt: maxAttempts } },
    { $inc: { attempts: 1 } }, { returnDocument: 'after' });
  }
  async verifyChallenge(id, hash, proofHash, now) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ _id: id, state: 'sent',
      otpHash: hash, expiresAt: { $gt: now } },
    { $set: { state: 'verified', proofHash, expiresAt: new Date(now.getTime() + 600000) },
      $unset: { otpHash: '' } }, { returnDocument: 'after' });
  }
  async claimProof(hash, now) {
    return this.db.collection('auth_challenges').findOneAndUpdate({ proofHash: hash,
      state: 'verified', expiresAt: { $gt: now } }, { $set: { state: 'registering' } },
    { returnDocument: 'after' });
  }
  async releaseProof(hash) {
    await this.db.collection('auth_challenges').updateOne({ proofHash: hash, state: 'registering' },
      { $set: { state: 'verified' } });
  }
  async consumeProof(hash) {
    await this.db.collection('auth_challenges').updateOne({ proofHash: hash }, { $set: { state: 'consumed' } });
  }
  async putSession(session) { await this.db.collection('auth_sessions').insertOne(session); }
  getSession(hash, now) { return this.db.collection('auth_sessions').findOne({ _id: hash, expiresAt: { $gt: now } }); }
}
module.exports = { MongoStore, initializeStore, inspectUsers };
