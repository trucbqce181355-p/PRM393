import 'package:hive_flutter/hive_flutter.dart';
import '../models/voucher.dart';
import 'mongodb_service.dart';

class DataService {
  static List<Voucher> vouchers = [];

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('fruitopia_db_v5');

    _loadData();
    await _syncFromMongoDB();
  }

  static void _loadData() {
    // Tải Vouchers
    final vouchersData = _box.get('vouchers');
    if (vouchersData != null) {
      vouchers = (vouchersData as List).map((e) => Voucher.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      vouchers = [
        Voucher(
          code: 'FREESHIP50',
          description: 'Miễn phí vận chuyển cho đơn từ 50k',
          discountAmount: 50000,
          minPurchase: 50000,
          isActive: true,
        ),
      ];
      _saveVouchers();
    }
  }

  static Future<void> _syncFromMongoDB() async {
    try {
      var colVouchers = MongoDBService.getCollection("vouchers");
      var remoteVouchers = await colVouchers.find().toList();
      if (remoteVouchers.isNotEmpty) {
        vouchers = remoteVouchers.map((e) {
          return Voucher(
            code: e['code']?.toString() ?? '',
            description: e['description']?.toString() ?? '',
            discountAmount: (e['discount_percent'] as num?)?.toDouble() ?? 0.0,
            minPurchase: (e['min_order_value'] as num?)?.toDouble() ?? 0.0,
            isActive: e['isActive'] ?? true,
          );
        }).toList();
        await _saveVouchers();
      }
    } catch (_) {}
  }

  static Future<void> _saveVouchers() async {
    await _box.put('vouchers', vouchers.map((e) => e.toJson()).toList());
  }

  // --- API Methods ---
  static Future<void> addVoucher(Voucher voucher) async {
    vouchers.add(voucher);
    await _saveVouchers();

    try {
      var col = MongoDBService.getCollection("vouchers");
      await col.insertOne({
        "code": voucher.code,
        "description": voucher.description,
        "discount_percent": voucher.discountAmount,
        "min_order_value": voucher.minPurchase,
        "isActive": voucher.isActive,
        "created_at": DateTime.now().toIso8601String()
      });
    } catch (_) {}
  }
}
