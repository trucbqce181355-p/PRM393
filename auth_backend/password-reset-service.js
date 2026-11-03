// Author: Chih An (GitHub: ChangChinAn)
// UC04: Đặt lại mật khẩu bằng bằng chứng OTP dành riêng cho password_reset.
const { digest } = require('./otp-request-service');
const { validatePassword, hashPassword } = require('./password-security');

class PasswordResetError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}
class PasswordResetService {
  constructor({ store, now = () => new Date() }) { this.store = store; this.now = now; }

  async reset({ verificationToken, password } = {}) {
    validatePassword(password);
    if (typeof verificationToken !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(verificationToken)) {
      throw new PasswordResetError(401, 'verification_expired', 'Vui lòng xác minh OTP đặt lại mật khẩu trước.');
    }
    const proofHash = digest(verificationToken);
    const challenge = await this.store.claimProof(proofHash, this.now());
    if (!challenge) {
      throw new PasswordResetError(401, 'verification_expired', 'Xác minh đặt lại mật khẩu đã hết hạn hoặc đã dùng. Vui lòng gửi lại OTP.');
    }
    try {
      const user = await this.store.findAccount(challenge.userId, challenge.email);
      if (!user) throw new PasswordResetError(404, 'account_missing', 'Tài khoản không còn tồn tại.');
      if (user.isActive === false) throw new PasswordResetError(403, 'account_locked', 'Tài khoản đã bị khóa.');
      await this.store.updatePassword(user.id, await hashPassword(password), this.now());
      await this.store.revokeSessions(user.id);
      await this.store.invalidateOtherResets(challenge.email, challenge._id);
      await this.store.consumeProof(proofHash);
      return { reset: true, email: user.email };
    } catch (error) {
      await this.store.releaseProof(proofHash);
      throw error;
    }
  }
}
module.exports = { PasswordResetService, PasswordResetError };
