// Author: Chih An (GitHub: ChangChinAn)
// UC11–UC12: Đọc thống kê thành viên và cập nhật họ tên/số điện thoại tài khoản.
class MongoProfileStore {
  constructor(db) { this.db = db; }
  async updateProfile(id, { name, phone }) {
    return this.db.collection('users').findOneAndUpdate({ id, isActive: { $ne: false },
      identityActive: { $ne: false }, mergedInto: { $exists: false } },
      { $set: { name, phone, profileUpdatedAt: new Date().toISOString() } },
      { returnDocument: 'after' });
  }
  async membership(email) {
    const escaped = email.trim().toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const [summary] = await this.db.collection('orders').aggregate([
      { $match: { customerEmail: { $regex: `^\\s*${escaped}\\s*$`, $options: 'i' },
        status: { $nin: ['Đã hủy', 'cancelled', 'canceled'] } } },
      { $group: { _id: null, totalOrders: { $sum: 1 }, totalSpent: { $sum: {
        $max: [0, { $convert: { input: '$totalAmount', to: 'double', onError: 0, onNull: 0 } }],
      } } } },
    ]).toArray();
    return { totalSpent: summary?.totalSpent ?? 0, totalOrders: summary?.totalOrders ?? 0 };
  }
}
module.exports = { MongoProfileStore };
