const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const { MongoClient } = require('mongodb');
const { inspectUsers } = require('./store');
(async () => {
  const client = new MongoClient(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017', { serverSelectionTimeoutMS: 5000 });
  try {
    await client.connect();
    const { users, conflicts, duplicateIds, invalid } = await inspectUsers(client.db(process.env.DB_NAME || 'traicay_db'));
    console.log(JSON.stringify({ userCount: users.length, conflicts, duplicateIds, invalid }, null, 2));
    if (conflicts.length || duplicateIds.length || invalid.length) process.exitCode = 1;
  } finally { await client.close(); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
