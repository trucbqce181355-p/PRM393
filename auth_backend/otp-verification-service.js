// Author: Chih An (GitHub: ChangChinAn)
// UC02: Xác minh OTP với hạn dùng, tối đa 5 lần thử và chống sử dụng lại.
const { randomBytes, timingSafeEqual } = require('node:crypto');
const { digest, MAX_OTP_ATTEMPTS } = require('./otp-request-service');

class OtpVerificationError extends Error {
  constructor(status, code, message, remainingAttempts = null) {
    super(message); this.status = status; this.code = code;
    this.remainingAttempts = remainingAttempts;
  }
}
class OtpVerificationService {
  constructor({ store, now = () => new Date() }) { this.store = store; this.now = now; }

  async unavailable(id, now) {
    const challenge = await this.store.getChallenge(id);
    if (challenge?.state === 'verified') {
      throw new OtpVerificationError(409, 'otp_used', 'Mã OTP đã được xác minh. Vui lòng không sử dụng lại.');
    }
    if (!challenge || challenge.state !== 'sent' || +challenge.expiresAt <= +now) {
      throw new OtpVerificationError(410, 'otp_expired', 'Mã OTP đã hết hạn hoặc đã được thay thế. Vui lòng gửi lại mã.');
    }
    throw new OtpVerificationError(429, 'otp_locked', 'Đã hết số lần thử OTP. Vui lòng gửi lại mã mới.', 0);
  }

  async verify(challengeId, otp, ip = 'unknown') {
    if (typeof challengeId !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(challengeId) ||
        typeof otp !== 'string' || !/^\d{6}$/.test(otp)) {
      throw new OtpVerificationError(400, 'otp_format', 'Vui lòng nhập đúng 6 chữ số OTP.');
    }
    const now = this.now();
    await this.store.limit(`verify-ip:${digest(ip)}`, 50, now);
    const challenge = await this.store.attemptOtp(challengeId, now, MAX_OTP_ATTEMPTS);
    if (!challenge) return this.unavailable(challengeId, now);
    const remaining = Math.max(0, MAX_OTP_ATTEMPTS - challenge.attempts);
    const hash = digest(`${challengeId}:${otp}`);
    const expected = Buffer.from(challenge.otpHash ?? '');
    const actual = Buffer.from(hash);
    if (expected.length !== actual.length || !timingSafeEqual(expected, actual)) {
      if (remaining === 0) {
        throw new OtpVerificationError(429, 'otp_locked', 'Đã hết số lần thử OTP. Vui lòng gửi lại mã mới.', 0);
      }
      throw new OtpVerificationError(400, 'otp_invalid', `Mã OTP không chính xác. Còn ${remaining} lần thử.`, remaining);
    }
    const verificationToken = randomBytes(32).toString('base64url');
    const expiresIn = 600;
    const verifiedAt = this.now();
    const verified = await this.store.verifyOtp(challengeId, hash, digest(verificationToken), verifiedAt,
      new Date(verifiedAt.getTime() + expiresIn * 1000));
    if (!verified) return this.unavailable(challengeId, this.now());
    return { verified: true, email: challenge.email, verificationToken, expiresIn,
      remainingAttempts: remaining };
  }
}
module.exports = { OtpVerificationService, OtpVerificationError };
