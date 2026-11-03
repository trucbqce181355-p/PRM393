import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/models/product.dart';

void main() {
  setUp(() {
    Cart.clear();
  });

  group('Quản lý giỏ hàng - Cập nhật số lượng sản phẩm trong giỏ Tests', () {
    final sampleProduct = Product(
      id: 'p_mang_cut',
      name: 'Măng Cụt Lái Thiêu',
      description: 'Măng cụt thơm ngon múi trắng ngần',
      price: 80000,
      unit: 'kg',
      imageUrl: '',
      rating: 5.0,
      stock: 50,
      category: 'Trái Cây Nhiệt Đới',
    );

    test('1. Cập nhật số lượng sản phẩm thành công (tăng số lượng)', () {
      Cart.addItem(sampleProduct, 1);
      expect(Cart.items.first.quantity, 1);
      expect(Cart.totalAmount, 80000.0);

      // Cập nhật lên 5 kg
      Cart.updateQuantity('p_mang_cut', 5);

      expect(Cart.items.first.quantity, 5);
      expect(Cart.items.first.totalPrice, 400000.0);
      expect(Cart.totalAmount, 400000.0);
    });

    test('2. Tăng / giảm số lượng thông qua changeQuantity (delta +/- 1)', () {
      Cart.addItem(sampleProduct, 2);
      expect(Cart.items.first.quantity, 2);

      // Nhấn nút [+] -> tăng thêm 1
      Cart.changeQuantity('p_mang_cut', 1);
      expect(Cart.items.first.quantity, 3);
      expect(Cart.totalAmount, 240000.0);

      // Nhấn nút [-] -> giảm đi 1
      Cart.changeQuantity('p_mang_cut', -1);
      expect(Cart.items.first.quantity, 2);
      expect(Cart.totalAmount, 160000.0);
    });

    test('3. Giảm số lượng về 0 hoặc số âm sẽ tự động xóa sản phẩm khỏi giỏ hàng', () {
      Cart.addItem(sampleProduct, 1);
      expect(Cart.items.length, 1);

      // Giảm 1 khi đang có 1 -> về 0 -> xóa
      Cart.changeQuantity('p_mang_cut', -1);

      expect(Cart.items, isEmpty);
      expect(Cart.totalAmount, 0.0);
    });

    test('4. Cập nhật số lượng bằng updateQuantity <= 0 tự động xóa khỏi giỏ', () {
      Cart.addItem(sampleProduct, 3);
      expect(Cart.items.length, 1);

      Cart.updateQuantity('p_mang_cut', 0);
      expect(Cart.items, isEmpty);
      expect(Cart.totalAmount, 0.0);
    });
  });
}
