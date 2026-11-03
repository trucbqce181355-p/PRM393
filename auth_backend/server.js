// Author: Chih An (GitHub: ChangChinAn)
// UC01–UC11: Xác thực tài khoản, quản lý phiên và xem hồ sơ/hạng thành viên.
const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const { MongoClient } = require('mongodb');
const nodemailer = require('nodemailer');
const { OtpRequestService } = require('./otp-request-service');
const { MongoOtpRequestStore } = require('./otp-request-store');
const { OtpVerificationService } = require('./otp-verification-service');
const { RegistrationService } = require('./registration-service');
const { MongoRegistrationStore } = require('./registration-store');
const { PasswordResetService } = require('./password-reset-service');
const { MongoPasswordResetStore } = require('./password-reset-store');
const { LoginService } = require('./login-service');
const { MongoLoginStore } = require('./login-store');
const { GoogleAuthService } = require('./google-auth-service');
const { MongoGoogleAuthStore } = require('./google-auth-store');
const { verifyGoogleToken } = require('./google-token-verifier');
const { GoogleProfileService } = require('./google-profile-service');
const { MongoGoogleProfileStore } = require('./google-profile-store');
const { SessionService } = require('./session-service');
const { MongoSessionStore } = require('./session-store');
const { ProfileService } = require('./profile-service');
const { MongoProfileStore } = require('./profile-store');

function createApp(service,
  verification = new OtpVerificationService({ store: service.store, now: service.now }),
  registration = new RegistrationService({ store: new MongoRegistrationStore(service.store.db), now: service.now }),
  passwordReset = new PasswordResetService({ store: new MongoPasswordResetStore(service.store.db), now: service.now }),
  login = new LoginService({ store: new MongoLoginStore(service.store.db), now: service.now }),
  google = new GoogleAuthService({ store: new MongoGoogleAuthStore(service.store.db), verifyGoogle: verifyGoogleToken, now: service.now }),
  googleProfile = new GoogleProfileService({ store: new MongoGoogleProfileStore(service.store.db), now: service.now }),
  sessions = new SessionService({ store: new MongoSessionStore(service.store.db), now: service.now }),
  profile = new ProfileService({ sessions, store: new MongoProfileStore(service.store.db) })) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '2kb' }));
  app.use((req, res, next) => { res.set('Cache-Control', 'no-store'); next(); });
  app.post('/api/auth/otp/request', (req, res, next) => {
    service.request(req.body?.email, req.ip, req.body?.purpose)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/otp/verify', (req, res, next) => {
    verification.verify(req.body?.challengeId, req.body?.otp, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/register', (req, res, next) => {
    registration.register(req.body)
      .then(data => res.status(201).json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/password/reset', (req, res, next) => {
    passwordReset.reset(req.body)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/login', (req, res, next) => {
    login.login(req.body, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/google', (req, res, next) => {
    const token = /^Bearer (.+)$/i.exec(req.headers.authorization ?? '')?.[1] ?? '';
    google.login(token, req.ip, req.body?.password)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.patch('/api/auth/google/profile', (req, res, next) => {
    const token = /^Bearer (.+)$/i.exec(req.headers.authorization ?? '')?.[1] ?? '';
    googleProfile.complete(token, req.body ?? {})
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.get('/api/auth/session', (req, res, next) => {
    const token = /^Bearer (.+)$/i.exec(req.headers.authorization ?? '')?.[1] ?? '';
    sessions.restore(token).then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/logout', (req, res, next) => {
    const token = /^Bearer (.+)$/i.exec(req.headers.authorization ?? '')?.[1] ?? '';
    sessions.logout(token).then(data => res.json({ success: true, data })).catch(next);
  });
  app.get('/api/auth/profile', (req, res, next) => {
    const token = /^Bearer (.+)$/i.exec(req.headers.authorization ?? '')?.[1] ?? '';
    profile.view(token).then(data => res.json({ success: true, data })).catch(next);
  });
  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    const status = error.status ?? 503;
    if (error.retryAfter > 0) res.set('Retry-After', String(error.retryAfter));
    res.status(status).json({ success: false,
      message: status < 500 ? error.message : 'Dịch vụ tài khoản tạm thời không khả dụng. Vui lòng thử lại sau.',
      retryAfter: error.retryAfter ?? 0,
      code: typeof error.code === 'string' ? error.code : undefined,
      remainingAttempts: error.remainingAttempts ?? undefined });
  });
  return app;
}
async function main() {
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017',
    { serverSelectionTimeoutMS: 5000 });
  await client.connect();
  const store = new MongoOtpRequestStore(client.db(process.env.DB_NAME || 'traicay_db'));
  await store.init();
  const registrationStore = new MongoRegistrationStore(store.db);
  await registrationStore.init();
  const loginStore = new MongoLoginStore(store.db);
  await loginStore.init();
  const googleStore = new MongoGoogleAuthStore(store.db);
  await googleStore.init();
  const transport = nodemailer.createTransport({ service: 'gmail',
    auth: { user: process.env.SMTP_USERNAME, pass: process.env.SMTP_PASSWORD },
    connectionTimeout: 10000, socketTimeout: 15000 });
  const service = new OtpRequestService({ store, sendEmail: async (email, otp, ttl, purpose) => {
    if (!process.env.SMTP_USERNAME || !process.env.SMTP_PASSWORD) throw new Error('SMTP is not configured');
    await transport.sendMail({ from: { name: 'Fruitopia OTP', address: process.env.SMTP_USERNAME },
      to: email, subject: purpose === 'password_reset' ? 'Mã đặt lại mật khẩu Fruitopia' : 'Mã xác minh email Fruitopia',
      text: `Mã OTP ${purpose === 'password_reset' ? 'đặt lại mật khẩu' : 'xác minh email'} của bạn: ${otp}. Mã có hiệu lực ${Math.ceil(ttl / 60)} phút. Không chia sẻ mã này.` });
  } });
  const registration = new RegistrationService({ store: registrationStore });
  const server = createApp(service, undefined, registration).listen(Number(process.env.PORT || 5001), process.env.HOST || '127.0.0.1', () => {
    console.log('Email verification and account registration service ready');
  });
  const close = () => server.close(async () => { await client.close(); process.exit(0); });
  process.once('SIGINT', close); process.once('SIGTERM', close);
}
module.exports = { createApp };
if (require.main === module) main().catch(() => { console.error('Cannot start UC01 service. Check MongoDB configuration.'); process.exitCode = 1; });
