const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const { randomUUID } = require('node:crypto');
const { MongoClient } = require('mongodb');
const { initializeStore, MongoStore } = require('./store');
const { normalizeEmail, validatePassword, hashPassword } = require('./security');
(async () => {
  const email = normalizeEmail(process.env.ADMIN_EMAIL);
  const password = process.env.ADMIN_PASSWORD;
  validatePassword(password);
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017');
  try {
    await client.connect();
    const db = client.db(process.env.DB_NAME || 'traicay_db');
    await initializeStore(db);
    const store = new MongoStore(db);
    if (await store.findEmail(email)) throw new Error('Email already exists; refusing to promote or overwrite an existing account.');
    await store.createUser({ id: `admin_${randomUUID()}`, email, emailNormalized: email,
      name: 'Quản trị viên', phone: '', role: 'admin', isActive: true, identityActive: true,
      password_hash: await hashPassword(password), totalSpent: 0, totalOrders: 0, memberTier: 'Đồng' });
    console.log('Admin account created. Remove ADMIN_PASSWORD from the local environment file.');
  } finally { await client.close(); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
