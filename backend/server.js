const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const admin = require('firebase-admin');
require('dotenv').config({ path: require('node:path').join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017';
const DB_NAME = process.env.DB_NAME || 'traicay_db';

app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK (nếu có serviceAccountKey hoặc credentials)
let firebaseInitialized = false;
try {
  const fs = require('fs');
  const path = require('path');
  const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseInitialized = true;
    console.log(' [Firebase Admin] Đã kết nối qua serviceAccountKey.json');
  } else {
    // Khởi tạo mặc định nếu có biến môi trường hoặc chế độ development
    admin.initializeApp();
    firebaseInitialized = true;
    console.log(' [Firebase Admin] Khởi tạo chế độ mặc định');
  }
} catch (err) {
  console.log('⚠️ [Firebase Admin] Chưa có credentials serviceAccountKey.json (chạy chế độ xác thực linh hoạt)');
}

let db;
let client;

async function connectDB() {
  try {
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db(DB_NAME);
    console.log(` [MongoDB] Đã kết nối thành công tới database: ${DB_NAME}`);
  } catch (error) {
    console.error('❌ [MongoDB] Lỗi kết nối:', error);
  }
}

// Middleware xác thực Firebase ID Token
async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Thiếu Authorization Bearer token' });
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    if (firebaseInitialized) {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      req.user = decodedToken;
      return next();
    } else {
      // Chế độ dev / fallback khi chưa gắn file key backend
      req.user = { uid: req.headers['x-user-uid'] || 'dev_user_uid' };
      return next();
    }
  } catch (error) {
    console.error('Lỗi xác thực Firebase token:', error);
    return res.status(401).json({ success: false, message: 'Token không hợp lệ hoặc đã hết hạn' });
  }
}

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'Fruitopia Backend API', time: new Date() });
});

// -------------------------------------------------------------
// 1. AUTH & PROFILE APIS
// -------------------------------------------------------------
app.get('/api/auth/profile/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const user = await db.collection('users').findOne({ $or: [{ id: uid }, { uid: uid }] });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Chưa có hồ sơ người dùng' });
    }
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/auth/profile', async (req, res) => {
  try {
    const { uid, name, email, phone } = req.body;
    if (!uid) {
      return res.status(400).json({ success: false, message: 'Thiếu uid người dùng' });
    }

    const updateDoc = {
      id: uid,
      uid: uid,
      name: name || '',
      email: email || '',
      phone: phone || '',
      role: 'customer',
      totalSpent: 0.0,
      totalOrders: 0,
      memberTier: 'Đồng',
      isActive: true,
      updated_at: new Date().toISOString(),
    };

    const result = await db.collection('users').updateOne(
      { $or: [{ id: uid }, { uid: uid }] },
      { $set: updateDoc, $setOnInsert: { created_at: new Date().toISOString() } },
      { upsert: true }
    );

    res.json({ success: true, message: 'Cập nhật hồ sơ thành công', data: updateDoc });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// -------------------------------------------------------------
// 2. PRODUCTS & CATEGORIES & VOUCHERS
// -------------------------------------------------------------
app.get('/api/products', async (req, res) => {
  try {
    const products = await db.collection('products').find({ isDeleted: { $ne: true } }).toArray();
    res.json({ success: true, data: products });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/categories', async (req, res) => {
  try {
    const categories = await db.collection('categories').find().toArray();
    res.json({ success: true, data: categories });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/vouchers', async (req, res) => {
  try {
    const vouchers = await db.collection('vouchers').find({ isActive: true }).toArray();
    res.json({ success: true, data: vouchers });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// -------------------------------------------------------------
// 3. ORDERS & TRACKING
// -------------------------------------------------------------
app.post('/api/orders', async (req, res) => {
  try {
    const { customerId, customerName, address, phone, items, total, paymentMethod } = req.body;
    const newOrder = {
      id: 'ORD' + Date.now().toString().slice(-6),
      customerId: customerId || 'anonymous',
      customerName: customerName || 'Khách hàng',
      address: address || '',
      phone: phone || '',
      items: items || [],
      total: total || 0,
      paymentMethod: paymentMethod || 'COD',
      status: 'preparing', // preparing -> delivering -> delivered
      trackingEvents: [
        {
          status: 'preparing',
          title: 'Đơn hàng đã được đặt',
          description: 'Fruitopia đang chuẩn bị những loại trái cây tươi ngon nhất cho bạn.',
          occurredAt: new Date().toISOString(),
        }
      ],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await db.collection('orders').insertOne(newOrder);
    res.json({ success: true, message: 'Tạo đơn hàng thành công', data: newOrder });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/orders', async (req, res) => {
  try {
    const { customerId } = req.query;
    const filter = customerId ? { customerId } : {};
    const orders = await db.collection('orders').find(filter).sort({ createdAt: -1 }).toArray();
    res.json({ success: true, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const order = await db.collection('orders').findOne({ id });
    if (!order) return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng' });
    res.json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.patch('/api/orders/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, note, actorId } = req.body;

    const statusDescriptions = {
      preparing: 'Đơn hàng đang được chuẩn bị và đóng gói',
      delivering: 'Shipper đã nhận hàng và đang trên đường giao tới bạn',
      delivered: 'Giao hàng thành công. Chúc bạn ngon miệng!',
      cancelled: 'Đơn hàng đã bị hủy',
    };

    const newEvent = {
      status,
      title: status === 'delivering' ? 'Đang giao hàng' : (status === 'delivered' ? 'Đã giao hàng' : 'Cập nhật trạng thái'),
      description: note || statusDescriptions[status] || 'Cập nhật trạng thái đơn hàng',
      actorId: actorId || 'admin',
      occurredAt: new Date().toISOString(),
    };

    await db.collection('orders').updateOne(
      { id },
      {
        $set: { status, updatedAt: new Date().toISOString() },
        $push: { trackingEvents: newEvent }
      }
    );

    res.json({ success: true, message: 'Đã cập nhật trạng thái đơn hàng' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 [Fruitopia Backend API] đang chạy tại: http://localhost:${PORT}`);
  });
});
