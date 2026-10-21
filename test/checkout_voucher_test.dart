import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/models/voucher.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  setUp(() {
    Cart.items.clear();

    DataService.vouchers = [
      Voucher(
        code: 'WELCOME10',
        description: 'Giảm 10.000₫ cho đơn từ 100.000₫',
        discountAmount: 10000,
        minPurchase: 100000,
        isActive: true,
      ),
      Voucher(
        code: 'FREESHIP20',
        description: 'Giảm 20.000₫ cho đơn từ 150.000₫',
        discountAmount: 20000,
        minPurchase: 150000,
        isActive: true,
      ),
      Voucher(
        code: 'FRUIT50K',
        description: 'Giảm 50.000₫ cho đơn từ 300.000₫',
        discountAmount: 50000,
        minPurchase: 300000,
        isActive: true,
      ),
      Voucher(
        code: 'EXPIRED100',
        description: 'Mã đã hết hạn',
        discountAmount: 100000,
        minPurchase: 50000,
        isActive: false, // Inactive
      ),
    ];
  });

  group('Quản lí thanh toán - Áp dụng voucher', () {
    test('1. Áp dụng voucher hợp lệ thành công và giảm trừ tiền thanh toán', () {
      // Đơn hàng: 185.000₫ (1 Táo Envy)
      final product = Product(
        id: 'p1',
        name: 'Táo Envy',
        description: 'Táo Envy',
        price: 185000,
        unit: 'kg',
        imageUrl: '',
      );
      Cart.items.add(CartItem(id: 'c1', product: product, quantity: 1));

      final originalTotal = Cart.totalAmount;
      expect(originalTotal, 185000);

      // Áp dụng voucher WELCOME10 (min 100k, giảm 10k)
      final voucher = DataService.vouchers.firstWhere(
        (v) => v.code == 'WELCOME10' && v.isActive,
      );
      expect(originalTotal >= voucher.minPurchase, isTrue);

      final discountAmount = voucher.discountAmount;
      final finalPaymentTotal = (originalTotal - discountAmount > 0)
          ? originalTotal - discountAmount
          : 0.0;

      expect(discountAmount, 10000);
      expect(finalPaymentTotal, 175000);
    });

    test('2. Từ chối áp dụng khi đơn hàng chưa đạt mức tối thiểu (minPurchase)', () {
      // Đơn hàng: 65.000₫ (1 Xoài Cát Chu)
      final product = Product(
        id: 'p2',
        name: 'Xoài Cát Chu',
        description: 'Xoài Cát Chu',
        price: 65000,
        unit: 'kg',
        imageUrl: '',
      );
      Cart.items.add(CartItem(id: 'c2', product: product, quantity: 1));

      final currentTotal = Cart.totalAmount;
      expect(currentTotal, 65000);

      // Thử áp dụng voucher WELCOME10 (yêu cầu tối thiểu 100.000₫)
      final voucher = DataService.vouchers.firstWhere((v) => v.code == 'WELCOME10');
      final isEligible = currentTotal >= voucher.minPurchase;

      expect(isEligible, isFalse);
      expect(voucher.minPurchase - currentTotal, 35000); // Còn thiếu 35.000₫
    });

    test('3. Từ chối mã voucher không tồn tại hoặc đã bị vô hiệu hóa (inactive)', () {
      Voucher? findActiveVoucher(String code) {
        try {
          return DataService.vouchers.firstWhere(
            (v) => v.code.toUpperCase() == code.toUpperCase() && v.isActive,
          );
        } catch (_) {
          return null;
        }
      }

      // Mã không tồn tại
      expect(findActiveVoucher('KHONG_TON_TAI'), isNull);

      // Mã đã hết hạn / ngưng hoạt động
      expect(findActiveVoucher('EXPIRED100'), isNull);
    });

    test('4. Hủy áp dụng voucher và khôi phục giá thanh toán ban đầu', () {
      final product = Product(
        id: 'p3',
        name: 'Cam Cara',
        description: 'Cam Cara',
        price: 220000,
        unit: 'kg',
        imageUrl: '',
      );
      Cart.items.add(CartItem(id: 'c3', product: product, quantity: 1));

      // Áp dụng voucher FREESHIP20
      String? appliedCode = 'FREESHIP20';
      double discountAmount = 20000;
      double total = Cart.totalAmount - discountAmount;
      expect(total, 200000);

      // Hủy voucher
      appliedCode = null;
      discountAmount = 0.0;
      total = Cart.totalAmount - discountAmount;

      expect(appliedCode, isNull);
      expect(discountAmount, 0.0);
      expect(total, 220000);
    });

    test('5. Tổng thanh toán không bao giờ âm khi voucher lớn hơn tổng tiền', () {
      final product = Product(
        id: 'p4',
        name: 'Thanh Long',
        description: 'Thanh Long',
        price: 45000,
        unit: 'kg',
        imageUrl: '',
      );
      Cart.items.add(CartItem(id: 'c4', product: product, quantity: 1));

      // Giả sử có voucher giảm 50.000₫
      const voucherDiscount = 50000.0;
      final finalPayment = (Cart.totalAmount - voucherDiscount > 0)
          ? Cart.totalAmount - voucherDiscount
          : 0.0;

      expect(finalPayment, 0.0);
    });

    test('6. Danh sách voucher khả dụng và kiểm tra tính hợp lệ theo giỏ hàng', () {
      // Giỏ hàng 160.000₫
      final product = Product(
        id: 'p5',
        name: 'Nho',
        description: 'Nho',
        price: 160000,
        unit: 'kg',
        imageUrl: '',
      );
      Cart.items.add(CartItem(id: 'c5', product: product, quantity: 1));

      final activeVouchers = DataService.vouchers.where((v) => v.isActive).toList();
      expect(activeVouchers.length, 3); // WELCOME10, FREESHIP20, FRUIT50K

      final eligibleVouchers = activeVouchers.where(
        (v) => Cart.totalAmount >= v.minPurchase,
      ).toList();

      // Đạt WELCOME10 (100k) và FREESHIP20 (150k), chưa đạt FRUIT50K (300k)
      expect(eligibleVouchers.length, 2);
      expect(eligibleVouchers.any((v) => v.code == 'WELCOME10'), isTrue);
      expect(eligibleVouchers.any((v) => v.code == 'FREESHIP20'), isTrue);
      expect(eligibleVouchers.any((v) => v.code == 'FRUIT50K'), isFalse);
    });
  });
}
