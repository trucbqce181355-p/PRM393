import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/models/product.dart';

void main() {
  setUp(() {
    Cart.clear();
  });

  group('Quản lý giỏ hàng - Thêm sản phẩm vào giỏ hàng Tests', () {
    final sampleProduct1 = Product(
      id: 'p_tao_envy',
      name: 'Táo Envy New Zealand',
      description: 'Táo Envy giòn ngọt đậm vị',
      price: 185000,
      unit: 'kg',
      imageUrl: '',
      rating: 5.0,
      stock: 50,
      category: 'Trái Cây Nhập Khẩu',
    );

    final sampleProduct2 = Product(
      id: 'p_cam_sanh',
      name: 'Cam Sành Tiền Giang',
      description: 'Cam sành mọng nước',
      price: 45000,
      unit: 'kg',
      imageUrl: '',
      rating: 4.8,
      stock: 80,
      category: 'Trái Cây Nhiệt Đới',
    );

    test('1. Thêm một sản phẩm mới vào giỏ hàng thành công', () {
      Cart.addItem(sampleProduct1, 2);

      expect(Cart.items.length, 1);
      expect(Cart.items.first.product.id, 'p_tao_envy');
      expect(Cart.items.first.quantity, 2);
      expect(Cart.items.first.totalPrice, 185000 * 2);
      expect(Cart.totalAmount, 370000.0);
      expect(Cart.totalQuantity, 2);
    });

    test('2. Thêm sản phẩm đã có trong giỏ hàng sẽ cộng dồn số lượng', () {
      Cart.addItem(sampleProduct1, 1);
      expect(Cart.items.first.quantity, 1);

      // Thêm tiếp 3 kg nữa
      Cart.addItem(sampleProduct1, 3);

      expect(Cart.items.length, 1, reason: 'Không tạo thêm dòng mới, chỉ tăng số lượng');
      expect(Cart.items.first.quantity, 4);
      expect(Cart.items.first.totalPrice, 185000 * 4);
      expect(Cart.totalAmount, 740000.0);
    });

    test('3. Thêm nhiều sản phẩm khác nhau vào giỏ hàng', () {
      Cart.addItem(sampleProduct1, 1);
      Cart.addItem(sampleProduct2, 3);

      expect(Cart.items.length, 2);
      expect(Cart.totalQuantity, 4);
      // 185,000 * 1 + 45,000 * 3 = 185,000 + 135,000 = 320,000
      expect(Cart.totalAmount, 320000.0);
    });

    test('4. Không thêm vào giỏ nếu số lượng truyền vào <= 0', () {
      Cart.addItem(sampleProduct1, 0);
      Cart.addItem(sampleProduct1, -2);

      expect(Cart.items, isEmpty);
      expect(Cart.totalAmount, 0.0);
    });
  });
}
