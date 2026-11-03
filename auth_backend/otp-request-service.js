// Author: Chih An (GitHub: ChangChinAn)
// UC01: Yêu cầu và gửi lại OTP xác minh email.
const { randomInt, randomBytes, createHash } = require('node:crypto');

class OtpRequestError extends Error {
  constructor(status, message, retryAfter = 0) {
    super(message); this.status = status; this.retryAfter = retryAfter;
  }
}
const digest = value => createHash('sha256').update(value).digest('hex');
const MAX_OTP_ATTEMPTS = 5;

class OtpRequestService {
  constructor({ store, sendEmail, now = () => new Date(), ttlSeconds = 300, resendSeconds = 60 }) {
    this.store = store; this.sendEmail = sendEmail; this.now = now;
    this.ttlSeconds = ttlSeconds; this.resendSeconds = resendSeconds;
  }

  async request(emailValue, ip = 'unknown') {
    if (typeof emailValue !== 'string') throw new OtpRequestError(400, 'Email không hợp lệ.');
    const email = emailValue.trim().toLowerCase();
    if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new OtpRequestError(400, 'Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (await this.store.emailExists(email)) {
      throw new OtpRequestError(409, 'Email đã được đăng ký.');
    }
    const now = this.now();
    await this.store.limit(`email:${digest(email)}`, 10, now);
    await this.store.limit(`ip:${digest(ip)}`, 20, now);
    await this.store.claimSendSlot(email, now, this.resendSeconds);
    const challengeId = randomBytes(32).toString('base64url');
    const otp = String(randomInt(100000, 1000000));
    await this.store.putChallenge({ _id: challengeId, email, purpose: 'registration',
      otpHash: digest(`${challengeId}:${otp}`), state: 'sending', attempts: 0,
      expiresAt: new Date(now.getTime() + this.ttlSeconds * 1000) });
    try {
      await this.sendEmail(email, otp, this.ttlSeconds);
      await this.store.activateChallenge(challengeId, email);
    } catch (_) {
      await this.store.removeChallenge(challengeId);
      throw new OtpRequestError(503, 'Không thể gửi email OTP. Vui lòng thử lại sau.');
    }
    // The OTP itself is delivered only by email, never in the response or logs.
    return { challengeId, email, expiresIn: this.ttlSeconds, resendAfter: this.resendSeconds,
      expiresAt: new Date(now.getTime() + this.ttlSeconds * 1000).toISOString(),
      maxAttempts: MAX_OTP_ATTEMPTS };
  }
}
module.exports = { OtpRequestService, OtpRequestError, digest, MAX_OTP_ATTEMPTS };
