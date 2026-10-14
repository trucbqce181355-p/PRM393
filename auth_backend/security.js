const crypto = require('node:crypto');

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
module.exports = { AuthError, digest, secret, equal, normalizeEmail };
