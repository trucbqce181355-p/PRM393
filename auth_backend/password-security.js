// Author: Chih An (GitHub: ChangChinAn)
// UC03–UC04: Chính sách mật khẩu và hash dùng chung khi tạo/đặt lại mật khẩu.
const { randomBytes, scrypt: scryptCallback } = require('node:crypto');
const { promisify } = require('node:util');
const scrypt = promisify(scryptCallback);

class PasswordValidationError extends Error {
  constructor() {
    super('Mật khẩu phải từ 12 đến 256 ký tự không dấu, có chữ hoa, chữ thường, số và ký tự đặc biệt; không có khoảng trắng đầu/cuối.');
    this.status = 400; this.code = 'invalid_password';
  }
}
function validatePassword(password) {
  if (typeof password !== 'string' || password.length < 12 || password.length > 256 ||
      password !== password.trim() || /[^\x20-\x7e]/.test(password) ||
      !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/\d/.test(password) ||
      !/[^A-Za-z0-9 ]/.test(password)) throw new PasswordValidationError();
}
async function hashPassword(password) {
  validatePassword(password);
  const salt = randomBytes(16).toString('hex');
  const key = await scrypt(password, salt, 64);
  return `scrypt$${salt}$${key.toString('hex')}`;
}
module.exports = { validatePassword, hashPassword };
