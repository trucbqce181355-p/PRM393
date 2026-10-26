const crypto = require('node:crypto');
const { promisify } = require('node:util');
const scrypt = promisify(crypto.scrypt);

class AuthError extends Error {
  constructor(status, message, code) { super(message); this.status = status; this.code = code; }
}
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
const secret = () => crypto.randomBytes(32).toString('base64url');
function equal(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const left = Buffer.from(a), right = Buffer.from(b);
  return left.length === right.length && crypto.timingSafeEqual(left, right);
}
function normalizeEmail(value) {
  if (typeof value !== 'string') throw new AuthError(400, 'Email không hợp lệ.');
  const email = value.trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new AuthError(400, 'Email không hợp lệ.');
  }
  return email;
}
function validateProfile(name, phone) {
  if (typeof name !== 'string' || !name.trim() || name.trim().length > 100 ||
      typeof phone !== 'string' || !/^0\d{9}$/.test(phone.trim())) {
    throw new AuthError(400, 'Họ tên hoặc số điện thoại không hợp lệ.');
  }
}
function validatePassword(password) {
  if (typeof password !== 'string' || password.length < 12 || password.length > 256 ||
      password !== password.trim() || /[^\x20-\x7e]/.test(password) ||
      !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/\d/.test(password) ||
      !/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?`~]/.test(password)) {
    throw new AuthError(400, 'Mật khẩu phải đáp ứng tiêu chuẩn an toàn.');
  }
}
async function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const key = await scrypt(password, salt, 64);
  return `scrypt$${salt}$${key.toString('hex')}`;
}
async function verifyPassword(password, user) {
  if (typeof password !== 'string' || password.length > 256) return false;
  const stored = user.password_hash ?? user.passwordHash ?? user.password;
  if (typeof stored !== 'string' || !stored) return false;
  if (stored.startsWith('scrypt$')) {
    const [, salt, hash] = stored.split('$');
    if (!/^[a-f0-9]{32}$/.test(salt ?? '') || !/^[a-f0-9]{128}$/.test(hash ?? '')) return false;
    return equal((await scrypt(password, salt, 64)).toString('hex'), hash);
  }
  // Existing SHA-256/plaintext records are upgraded after a successful login.
  if (/^[a-f0-9]{64}$/i.test(stored) && (user.password_hash != null || user.passwordHash != null)) {
    return equal(stored.toLowerCase(), digest(password.trim()));
  }
  return equal(stored, password.trim());
}
function publicUser(user) {
  return {
    id: user.id, name: user.name ?? '', email: user.email ?? '', phone: user.phone ?? '',
    totalSpent: user.totalSpent ?? 0, totalOrders: user.totalOrders ?? 0,
    memberTier: user.memberTier ?? 'Đồng', isActive: user.isActive !== false,
    role: user.role === 'admin' ? 'admin' : 'customer',
    profileCompleted: Boolean(user.name?.trim() && user.phone?.trim()),
    hasPassword: Boolean(user.password_hash ?? user.passwordHash ?? user.password),
    sessionProvider: user.sessionProvider === 'google' ? 'google' : 'password',
  };
}
module.exports = { AuthError, digest, secret, equal, normalizeEmail, validateProfile,
  validatePassword, hashPassword, verifyPassword, publicUser };
