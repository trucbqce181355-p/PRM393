import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quản lí thanh toán - Tính phí vận chuyển và tổng hóa đơn', () {
    double calculateShippingFee(double subtotal, String method) {
      if (method == 'EXPRESS') {
        return 35000.0;
      }
      return subtotal >= 300000 ? 0.0 : 20000.0;
    }

    double calculateInvoiceTotal({
      required double subtotal,
      required String shippingMethod,
      double voucherDiscount = 0.0,
    }) {
      final shippingFee = calculateShippingFee(subtotal, shippingMethod);
      final total = subtotal + shippingFee - voucherDiscount;
      return total > 0 ? total : 0.0;
    }

    test('1. Đơn hàng dưới 300.000₫ áp dụng phí giao hàng tiêu chuẩn 20.000₫', () {
      const subtotal = 185000.0; // 1 Táo Envy
      final fee = calculateShippingFee(subtotal, 'STANDARD');
      expect(fee, 20000.0);

      final total = calculateInvoiceTotal(
        subtotal: subtotal,
        shippingMethod: 'STANDARD',
      );
      expect(total, 205000.0);
    });

    test('2. Đơn hàng từ 300.000₫ trở lên được miễn phí vận chuyển tiêu chuẩn', () {
      const subtotal = 420000.0; // 1 Nho Mẫu Đơn
      final fee = calculateShippingFee(subtotal, 'STANDARD');
      expect(fee, 0.0);

      final total = calculateInvoiceTotal(
        subtotal: subtotal,
        shippingMethod: 'STANDARD',
      );
      expect(total, 420000.0);
    });

    test('3. Giao hàng hỏa tốc tính phí 35.000₫ bất kể giá trị đơn hàng', () {
      const subtotal = 500000.0;
      final fee = calculateShippingFee(subtotal, 'EXPRESS');
      expect(fee, 35000.0);

      final total = calculateInvoiceTotal(
        subtotal: subtotal,
        shippingMethod: 'EXPRESS',
      );
      expect(total, 535000.0);
    });

    test('4. Tính tổng hóa đơn kết hợp phí ship và voucher giảm giá chính xác', () {
      const subtotal = 250000.0;
      const voucherDiscount = 20000.0; // Voucher giảm 20k

      // Tiêu chuẩn: 250.000 + 20.000 ship - 20.000 voucher = 250.000₫
      final totalStandard = calculateInvoiceTotal(
        subtotal: subtotal,
        shippingMethod: 'STANDARD',
        voucherDiscount: voucherDiscount,
      );
      expect(totalStandard, 250000.0);

      // Hỏa tốc: 250.000 + 35.000 ship - 20.000 voucher = 265.000₫
      final totalExpress = calculateInvoiceTotal(
        subtotal: subtotal,
        shippingMethod: 'EXPRESS',
        voucherDiscount: voucherDiscount,
      );
      expect(totalExpress, 265000.0);
    });

    test('5. Tổng hóa đơn không bao giờ âm khi voucher lớn hơn tiền hàng và ship', () {
      const subtotal = 50000.0;
      const voucherDiscount = 100000.0;

      final total = calculateInvoiceTotal(
        subtotal: subtotal,
        shippingMethod: 'STANDARD',
        voucherDiscount: voucherDiscount,
      );
      expect(total, 0.0);
    });
  });
}
