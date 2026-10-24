import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/models/product.dart';

void main() {
  setUp(() {
    Cart.clear();
  });

  group('Quản lý giỏ hàng - Xem giỏ hàng Tests', () {
    final sampleProduct1 = Product(
      id: 'p_nho_xanh',
      name: 'Nho Xanh Autumn Crisp Mỹ',
      description: 'Nho xanh giòn ngọt không hạt',
      price: 220000,
      unit: 'kg',
      imageUrl: 'https://example.com/nho.jpg',
      rating: 5.0,
      stock: 45,
      category: 'Trái Cây Nhập Khẩu',
    );

    final sampleProduct2 = Product(
      id: 'p_sau_rieng',
      name: 'Sầu Riêng Ri6',
      description: 'Cơm vàng hạt lép',
      price: 145000,
      unit: 'kg',
      imageUrl: 'https://example.com/saurieng.jpg',
      rating: 4.9,
      stock: 30,
      category: 'Trái Cây Nhiệt Đới',
    );

    test('1. Xem giỏ hàng ban đầu khi chưa có sản phẩm (giỏ hàng rỗng)', () {
      expect(Cart.isEmpty, isTrue);
      expect(Cart.isNotEmpty, isFalse);
      expect(Cart.items, isEmpty);
      expect(Cart.totalAmount, 0.0);
      expect(Cart.totalQuantity, 0);
    });

    test('2. Xem chi tiết danh sách sản phẩm trong giỏ hàng', () {
      Cart.addItem(sampleProduct1, 2);
      Cart.addItem(sampleProduct2, 1);

      expect(Cart.isEmpty, isFalse);
      expect(Cart.isNotEmpty, isTrue);
      expect(Cart.items.length, 2);

      // Kiểm tra món 1
      final item1 = Cart.items[0];
      expect(item1.product.name, 'Nho Xanh Autumn Crisp Mỹ');
      expect(item1.product.price, 220000);
      expect(item1.product.unit, 'kg');
      expect(item1.quantity, 2);
      expect(item1.totalPrice, 440000.0);

      // Kiểm tra món 2
      final item2 = Cart.items[1];
      expect(item2.product.name, 'Sầu Riêng Ri6');
      expect(item2.quantity, 1);
      expect(item2.totalPrice, 145000.0);
    });

    test('3. Xem tổng tiền và tổng số lượng sản phẩm chính xác', () {
      Cart.addItem(sampleProduct1, 3); // 220,000 * 3 = 660,000
      Cart.addItem(sampleProduct2, 2); // 145,000 * 2 = 290,000

      expect(Cart.totalQuantity, 5);
      expect(Cart.totalAmount, 950000.0);
    });
  });
}
