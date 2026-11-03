// Author: Chih An (GitHub: ChangChinAn)
// UC03: Tạo tài khoản bằng email đã xác minh, mật khẩu và thông tin cá nhân.
const { randomBytes, randomUUID, scrypt: scryptCallback } = require('node:crypto');
const { promisify } = require('node:util');
const { digest } = require('./otp-request-service');
const scrypt = promisify(scryptCallback);

class RegistrationError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}

function validateRegistration(name, phone, password) {
  if (typeof name !== 'string' || !name.trim() || name.trim().length > 100 ||
      typeof phone !== 'string' || !/^0\d{9}$/.test(phone.trim())) {
    throw new RegistrationError(400, 'invalid_profile', 'Họ tên hoặc số điện thoại không hợp lệ.');
  }
  if (typeof password !== 'string' || password.length < 12 || password.length > 256 ||
      password !== password.trim() || /[^\x20-\x7e]/.test(password) ||
      !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/\d/.test(password) ||
      !/[^A-Za-z0-9 ]/.test(password)) {
    throw new RegistrationError(400, 'invalid_password',
      'Mật khẩu phải từ 12 đến 256 ký tự không dấu, có chữ hoa, chữ thường, số và ký tự đặc biệt; không có khoảng trắng đầu/cuối.');
  }
}

class RegistrationService {
  constructor({ store, now = () => new Date() }) { this.store = store; this.now = now; }

  async register({ verificationToken, name, phone, password } = {}) {
    validateRegistration(name, phone, password);
    if (typeof verificationToken !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(verificationToken)) {
      throw new RegistrationError(401, 'verification_expired', 'Vui lòng xác minh email trước khi tạo tài khoản.');
    }
    const proofHash = digest(verificationToken);
    const challenge = await this.store.claimProof(proofHash, this.now());
    if (!challenge) {
      throw new RegistrationError(401, 'verification_expired', 'Xác minh email đã hết hạn hoặc đã được sử dụng. Vui lòng xác minh lại.');
    }
    try {
      const salt = randomBytes(16).toString('hex');
      const key = await scrypt(password, salt, 64);
      const user = await this.store.createUser({
        id: `c_${randomUUID()}`, email: challenge.email, emailNormalized: challenge.email,
        emailVerified: true, name: name.trim(), phone: phone.trim(),
        password_hash: `scrypt$${salt}$${key.toString('hex')}`,
        role: 'customer', isActive: true, identityActive: true,
        totalSpent: 0, totalOrders: 0, memberTier: 'Đồng',
        created_at: this.now().toISOString(),
      });
      await this.store.consumeProof(proofHash);
      // Return only public registration data; password/hash never leave the server.
      return { customer: { id: user.id, name: user.name, email: user.email,
        phone: user.phone, emailVerified: true } };
    } catch (error) {
      await this.store.releaseProof(proofHash);
      throw error;
    }
  }
}
module.exports = { RegistrationService, RegistrationError };
