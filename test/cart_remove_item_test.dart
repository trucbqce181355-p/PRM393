import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/models/product.dart';

void main() {
  setUp(() {
    Cart.clear();
  });

  group('Quản lý giỏ hàng - Xóa sản phẩm khỏi giỏ hàng Tests', () {
    final sampleProduct1 = Product(
      id: 'p_sau_rieng',
      name: 'Sầu Riêng Ri6',
      description: 'Cơm vàng hạt lép',
      price: 150000,
      unit: 'kg',
      imageUrl: '',
      rating: 5.0,
      stock: 40,
      category: 'Trái Cây Nhiệt Đới',
    );

    final sampleProduct2 = Product(
      id: 'p_thanh_long',
      name: 'Thanh Long Ruột Đỏ',
      description: 'Thanh long ngọt mát bổ dưỡng',
      price: 35000,
      unit: 'kg',
      imageUrl: '',
      rating: 4.7,
      stock: 100,
      category: 'Trái Cây Nhiệt Đới',
    );

    test('1. Xóa một sản phẩm cụ thể khỏi giỏ hàng bằng removeItem', () {
      Cart.addItem(sampleProduct1, 2);
      Cart.addItem(sampleProduct2, 3);
      expect(Cart.items.length, 2);
      expect(Cart.totalAmount, (150000 * 2) + (35000 * 3)); // 405,000₫

      // Xóa Sầu riêng khỏi giỏ
      Cart.removeItem('p_sau_rieng');

      expect(Cart.items.length, 1);
      expect(Cart.items.first.product.id, 'p_thanh_long');
      expect(Cart.totalAmount, 35000 * 3); // 105,000₫
    });

    test('2. Xóa sản phẩm không tồn tại trong giỏ hàng xử lý an toàn', () {
      Cart.addItem(sampleProduct1, 1);
      expect(Cart.items.length, 1);

      // Thử xóa một sản phẩm không có trong giỏ
      Cart.removeItem('p_unknown');

      expect(Cart.items.length, 1);
      expect(Cart.items.first.product.id, 'p_sau_rieng');
    });

    test('3. Xóa toàn bộ sản phẩm trong giỏ hàng bằng Cart.clear()', () {
      Cart.addItem(sampleProduct1, 1);
      Cart.addItem(sampleProduct2, 2);
      expect(Cart.isEmpty, isFalse);

      Cart.clear();

      expect(Cart.isEmpty, isTrue);
      expect(Cart.items, isEmpty);
      expect(Cart.totalAmount, 0.0);
      expect(Cart.totalQuantity, 0);
    });

    test('4. Xóa món hàng duy nhất trong giỏ khiến giỏ hàng trở về trạng thái trống', () {
      Cart.addItem(sampleProduct1, 1);
      expect(Cart.isNotEmpty, isTrue);

      Cart.removeItem('p_sau_rieng');

      expect(Cart.isEmpty, isTrue);
      expect(Cart.items, isEmpty);
    });
  });
}
