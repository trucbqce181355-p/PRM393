const crypto = require('node:crypto');

class AuthError extends Error {
  constructor(status, message, code) { super(message); this.status = status; this.code = code; }
}
const digest = value => crypto.createHash('sha256').update(value).digest('hex');
const secret = () => crypto.randomBytes(32).toString('base64url');
function normalizeEmail(value) {
  if (typeof value !== 'string') throw new AuthError(400, 'Email không hợp lệ.');
  const email = value.trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new AuthError(400, 'Email không hợp lệ.');
  }
  return email;
}
module.exports = { AuthError, digest, secret, normalizeEmail };
