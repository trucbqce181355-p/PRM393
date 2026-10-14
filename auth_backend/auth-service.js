const { randomInt } = require('node:crypto');
const { AuthError, digest, secret, normalizeEmail } = require('./security');

class AuthService {
  constructor({ store, sendEmail, now = () => new Date(), config = {} }) {
    this.store = store; this.sendEmail = sendEmail; this.now = now;
    this.config = { otpTtl: 300, resend: 60, ...config };
  }
  async requestOtp(emailValue, ip) {
    const email = normalizeEmail(emailValue), now = this.now();
    await this.store.limit(`otp-ip:${digest(ip)}`, 3600, 20, now);
    await this.store.limit(`otp-email:${digest(email)}`, 3600, 10, now);
    await this.store.cooldown(`otp-cooldown:${digest(email)}`, this.config.resend, now);
    if (await this.store.findEmail(email)) throw new AuthError(409, 'Email đã được đăng ký. Vui lòng đăng nhập.');
    const id = secret(), otp = String(randomInt(100000, 1000000));
    await this.store.putChallenge({ _id: id, email, otpHash: digest(`${id}:${otp}`),
      state: 'sending', attempts: 0, expiresAt: new Date(now.getTime() + this.config.otpTtl * 1000) });
    try {
      await this.sendEmail(email, otp, this.config.otpTtl);
      await this.store.activateChallenge(id);
    } catch (error) {
      await this.store.removeChallenge(id);
      throw error;
    }
    return { challengeId: id, expiresIn: this.config.otpTtl, resendAfter: this.config.resend };
  }
}
module.exports = { AuthService };
