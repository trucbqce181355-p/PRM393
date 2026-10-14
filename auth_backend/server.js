const path = require('node:path');
const fs = require('node:fs');
const { createHash } = require('node:crypto');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const { MongoClient } = require('mongodb');
const nodemailer = require('nodemailer');
const { AuthError, publicUser } = require('./security');
const { MongoStore, initializeStore } = require('./store');
const { AuthService } = require('./auth-service');

const revision = createHash('sha256').update(['server.js', 'auth-service.js', 'security.js', 'store.js']
  .map(file => fs.readFileSync(path.join(__dirname, file), 'utf8')).join('\n')).digest('hex');

async function main() {
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017',
    { serverSelectionTimeoutMS: 5000 });
  await client.connect();
  const db = client.db(process.env.DB_NAME || 'traicay_db');
  try { await db.command({ ping: 1 }); } catch (error) { await client.close(); throw error; }
  try { await initializeStore(db); } catch (error) { await client.close(); throw error; }
  const smtp = nodemailer.createTransport({ service: 'gmail',
    auth: { user: process.env.SMTP_USERNAME, pass: process.env.SMTP_PASSWORD },
    connectionTimeout: 10000, socketTimeout: 15000 });
  const service = new AuthService({ store: new MongoStore(db),
    sendEmail: async (email, otp, ttl) => {
      if (!process.env.SMTP_USERNAME || !process.env.SMTP_PASSWORD) {
        throw new AuthError(503, 'Server chưa cấu hình gửi email.');
      }
      await smtp.sendMail({ from: { name: 'Fruitopia OTP', address: process.env.SMTP_USERNAME },
        to: email, subject: 'Mã xác thực OTP Fruitopia',
        text: `Mã OTP của bạn: ${otp}. Mã có hiệu lực ${Math.ceil(ttl / 60)} phút. Không chia sẻ mã này.` });
    }, verifyGoogle: verifyGoogleToken, config: { otpTtl: positiveInt('OTP_TTL_SECONDS', 300),
      attempts: positiveInt('OTP_MAX_ATTEMPTS', 5), resend: positiveInt('OTP_RESEND_SECONDS', 60),
      sessionTtl: positiveInt('SESSION_TTL_SECONDS', 604800) },
  });

  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));
  app.use((req, res, next) => { res.set('Cache-Control', 'no-store'); next(); });
  app.post('/api/auth/otp/request', (req, res, next) => {
    service.requestOtp(req.body.email, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/otp/verify', (req, res, next) => {
    service.verifyOtp(req.body.challengeId, req.body.otp)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/register', (req, res, next) => {
    service.register(req.body)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/login', (req, res, next) => {
    service.login(req.body.email, req.body.password, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/google', (req, res, next) => {
    const token = (req.headers.authorization ?? '').replace(/^Bearer /, '');
    service.google(token, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.get('/api/auth/session', (req, res, next) => {
    const token = (req.headers.authorization ?? '').replace(/^Bearer /, '');
    service.authenticate(token)
      .then(user => res.json({ success: true, data: publicUser(user) })).catch(next);
  });
  app.get('/api/health', async (req, res) => {
    try {
      await db.command({ ping: 1 });
      res.json({ success: true, data: { status: 'ok', service: 'fruitopia-auth', revision, pid: process.pid } });
    } catch {
      res.status(503).json({ success: false, message: 'Không kết nối được cơ sở dữ liệu.' });
    }
  });
  app.use((req, res) => res.status(404).json({ success: false, message: 'API chưa được triển khai.' }));
  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    const status = error.status ?? 503;
    if (status >= 500) console.error('[Auth backend]', req.method, req.path, error.name, error.code ?? 'service_error');
    res.status(status).json({ success: false,
      code: typeof error.code === 'string' ? error.code : undefined, message: error.status ? error.message
      : 'Không thể lưu hoặc xác minh dữ liệu. Vui lòng thử lại sau.' });
  });

  const server = app.listen(Number(process.env.PORT || 5001), process.env.HOST || '127.0.0.1', () => {
    console.log('Fruitopia Auth backend ready on port', process.env.PORT || 5001);
  });
  server.once('error', async () => {
    console.error('Cannot start auth backend. Check host and port.');
    await client.close(); process.exitCode = 1;
  });
  const close = () => server.close(async () => { await client.close(); process.exit(0); });
  process.once('SIGINT', close); process.once('SIGTERM', close);
}
async function verifyGoogleToken(token) {
  const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) throw new AuthError(503, 'Server chưa cấu hình Supabase.');
  let response;
  try {
    response = await fetch(`${url.replace(/\/$/, '')}/auth/v1/user`, {
      headers: { apikey: key, Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(10000) });
  } catch (cause) {
    const error = new AuthError(503,
      'Máy chủ không kết nối được dịch vụ xác thực Google. Vui lòng thử lại sau.',
      'google_verification_unavailable');
    error.cause = cause;
    throw error;
  }
  if (response.status === 429 || response.status >= 500) {
    throw new AuthError(503, 'Dịch vụ xác thực Google đang bận. Vui lòng thử lại sau.',
      'google_verification_unavailable');
  }
  if (!response.ok) throw new AuthError(401, 'Phiên Google không hợp lệ hoặc đã hết hạn.');
  try { return await response.json(); } catch {
    throw new AuthError(503, 'Dịch vụ xác thực Google trả về dữ liệu không hợp lệ.',
      'google_verification_unavailable');
  }
}
function positiveInt(key, fallback) {
  const value = Number(process.env[key] ?? fallback);
  if (!Number.isSafeInteger(value) || value < 1) throw new Error(`Invalid ${key}`);
  return value;
}
main().catch(error => { console.error('Auth backend startup failed:', error.name); process.exitCode = 1; });
