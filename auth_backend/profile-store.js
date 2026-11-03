// Author: Chih An (GitHub: ChangChinAn)
// UC11: Đọc thống kê thành viên từ các đơn chưa bị hủy của đúng email tài khoản.
class MongoProfileStore {
  constructor(db) { this.db = db; }
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
