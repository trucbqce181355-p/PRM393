const path = require('node:path');
const fs = require('node:fs');
const { createHash } = require('node:crypto');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const { MongoClient } = require('mongodb');

const revision = createHash('sha256')
  .update(fs.readFileSync(__filename, 'utf8')).digest('hex');

async function main() {
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017',
    { serverSelectionTimeoutMS: 5000 });
  await client.connect();
  const db = client.db(process.env.DB_NAME || 'traicay_db');
  try { await db.command({ ping: 1 }); } catch (error) { await client.close(); throw error; }

  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));
  app.use((req, res, next) => { res.set('Cache-Control', 'no-store'); next(); });
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
    const status = error.status === 400 || error.status === 413 ? error.status : 503;
    res.status(status).json({ success: false, message: 'Không thể xử lý yêu cầu.' });
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
main().catch(error => { console.error('Auth backend startup failed:', error.name); process.exitCode = 1; });
