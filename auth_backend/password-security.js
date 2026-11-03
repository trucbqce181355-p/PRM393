// Author: Chih An (GitHub: ChangChinAn)
// UC03–UC05: Chính sách, hash và đối chiếu mật khẩu khi đăng ký/đặt lại/đăng nhập.
const { randomBytes, scrypt: scryptCallback, timingSafeEqual, createHash } = require('node:crypto');
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
async function hashPassword(password, { enforcePolicy = true } = {}) {
  if (enforcePolicy) validatePassword(password);
  const salt = randomBytes(16).toString('hex');
  const key = await scrypt(password, salt, 64);
  return `scrypt$${salt}$${key.toString('hex')}`;
}
function equalStrings(left, right) {
  if (typeof left !== 'string' || typeof right !== 'string') return false;
  const a = Buffer.from(left), b = Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}
async function verifyPassword(password, user) {
  if (typeof password !== 'string' || !password || password.length > 256) return false;
  const stored = user.password_hash ?? user.passwordHash ?? user.password;
  if (typeof stored !== 'string' || !stored) return false;
  if (stored.startsWith('scrypt$')) {
    if (!/^scrypt\$[a-f0-9]{32}\$[a-f0-9]{128}$/.test(stored)) return false;
    const [, salt, expected] = stored.split('$');
    const actual = await scrypt(password, salt, 64);
    return equalStrings(actual.toString('hex'), expected);
  }
  // Existing SHA-256/plaintext records are upgraded only after a successful login.
  if (/^[a-f0-9]{64}$/i.test(stored) && (user.password_hash != null || user.passwordHash != null)) {
    return equalStrings(stored.toLowerCase(), createHash('sha256').update(password.trim()).digest('hex'));
  }
  return equalStrings(stored, password.trim());
}
module.exports = { validatePassword, hashPassword, verifyPassword };
