import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/voucher.dart';

void main() {
  group('Voucher Model & CRUD Logic Tests', () {
    test('Voucher serialization and deserialization', () {
      final voucher = Voucher(
        code: 'TEST50',
        description: 'Giảm 50.000₫',
        discountAmount: 50000.0,
        minPurchase: 200000.0,
        isActive: true,
      );

      final json = voucher.toJson();
      expect(json['code'], 'TEST50');
      expect(json['discountAmount'], 50000.0);
      expect(json['minPurchase'], 200000.0);
      expect(json['isActive'], true);

      final fromJson = Voucher.fromJson(json);
      expect(fromJson.code, voucher.code);
      expect(fromJson.description, voucher.description);
      expect(fromJson.discountAmount, voucher.discountAmount);
      expect(fromJson.minPurchase, voucher.minPurchase);
      expect(fromJson.isActive, voucher.isActive);
    });

    test('Voucher copyWith modifies fields correctly', () {
      final original = Voucher(
        code: 'SALE10',
        description: 'Giảm 10k',
        discountAmount: 10000.0,
        minPurchase: 50000.0,
        isActive: true,
      );

      final updated = original.copyWith(
        code: 'SALE20',
        discountAmount: 20000.0,
        isActive: false,
      );

      expect(updated.code, 'SALE20');
      expect(updated.description, 'Giảm 10k');
      expect(updated.discountAmount, 20000.0);
      expect(updated.minPurchase, 50000.0);
      expect(updated.isActive, false);
    });

    test('Voucher handles legacy MongoDB field names', () {
      final mongoJson = {
        'code': 'LEGACY10',
        'description': 'Mã cũ',
        'discount_percent': 15000,
        'min_order_value': 100000,
        'isActive': true,
      };

      final v = Voucher.fromJson(mongoJson);
      expect(v.code, 'LEGACY10');
      expect(v.discountAmount, 15000.0);
      expect(v.minPurchase, 100000.0);
      expect(v.isActive, true);
    });
  });
}
