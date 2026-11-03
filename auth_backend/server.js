// Author: Chih An (GitHub: ChangChinAn)
// UC01–UC02: Endpoint gửi/gửi lại và xác minh OTP email.
const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const { MongoClient } = require('mongodb');
const nodemailer = require('nodemailer');
const { OtpRequestService } = require('./otp-request-service');
const { MongoOtpRequestStore } = require('./otp-request-store');
const { OtpVerificationService } = require('./otp-verification-service');

function createApp(service, verification = new OtpVerificationService({ store: service.store, now: service.now })) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '2kb' }));
  app.use((req, res, next) => { res.set('Cache-Control', 'no-store'); next(); });
  app.post('/api/auth/otp/request', (req, res, next) => {
    service.request(req.body?.email, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.post('/api/auth/otp/verify', (req, res, next) => {
    verification.verify(req.body?.challengeId, req.body?.otp, req.ip)
      .then(data => res.json({ success: true, data })).catch(next);
  });
  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    const status = error.status ?? 503;
    if (error.retryAfter > 0) res.set('Retry-After', String(error.retryAfter));
    res.status(status).json({ success: false,
      message: status < 500 ? error.message : 'Dịch vụ OTP tạm thời không khả dụng. Vui lòng thử lại sau.',
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
  const transport = nodemailer.createTransport({ service: 'gmail',
    auth: { user: process.env.SMTP_USERNAME, pass: process.env.SMTP_PASSWORD },
    connectionTimeout: 10000, socketTimeout: 15000 });
  const service = new OtpRequestService({ store, sendEmail: async (email, otp, ttl) => {
    if (!process.env.SMTP_USERNAME || !process.env.SMTP_PASSWORD) throw new Error('SMTP is not configured');
    await transport.sendMail({ from: { name: 'Fruitopia OTP', address: process.env.SMTP_USERNAME },
      to: email, subject: 'Mã xác minh email Fruitopia',
      text: `Mã OTP của bạn: ${otp}. Mã có hiệu lực ${Math.ceil(ttl / 60)} phút. Không chia sẻ mã này.` });
  } });
  const server = createApp(service).listen(Number(process.env.PORT || 5001), process.env.HOST || '127.0.0.1', () => {
    console.log('UC01 email OTP service ready');
  });
  const close = () => server.close(async () => { await client.close(); process.exit(0); });
  process.once('SIGINT', close); process.once('SIGTERM', close);
}
module.exports = { createApp };
if (require.main === module) main().catch(() => { console.error('Cannot start UC01 service. Check MongoDB configuration.'); process.exitCode = 1; });
