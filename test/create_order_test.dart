import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/models/order.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/models/customer.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Cart.items.clear();
    DataService.orders = [];
    DataService.customers = [
      Customer(
        id: 'cust_01',
        name: 'Trần Văn Hùng',
        email: 'hungtv@fruitopia.vn',
        phone: '0901234567',
        password: 'password123',
        totalSpent: 100000.0,
        totalOrders: 1,
        memberTier: 'Đồng',
      ),
    ];
  });

  group('Quản lí thanh toán - Tạo đơn hàng Tests', () {
    final sampleProduct1 = Product(
      id: 'p1',
      name: 'Táo Envy New Zealand',
      description: 'Táo tươi giòn nhập khẩu',
      price: 180000,
      unit: 'kg',
      imageUrl: '',
      rating: 5.0,
      stock: 50,
      category: 'Trái Cây Nhập Khẩu',
    );

    final sampleProduct2 = Product(
      id: 'p2',
      name: 'Xoài Cát Chu Cao Lãnh',
      description: 'Xoài cát ngọt thơm đặc sản',
      price: 65000,
      unit: 'kg',
      imageUrl: '',
      rating: 4.8,
      stock: 100,
      category: 'Trái Cây Nhiệt Đới',
    );

    test('1. Tạo đối tượng Order với thông tin người nhận, địa chỉ, tổng tiền và mã đơn DH...', () {
      final orderId = 'DH${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final order = Order(
        id: orderId,
        customerName: 'Trần Văn Hùng',
        customerEmail: 'hungtv@fruitopia.vn',
        customerPhone: '0901234567',
        address: '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
        totalAmount: 245000.0,
        itemsSummary: 'Táo Envy New Zealand (x1) + Xoài Cát Chu Cao Lãnh (x1)',
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(order.id, startsWith('DH'));
      expect(order.customerName, 'Trần Văn Hùng');
      expect(order.customerEmail, 'hungtv@fruitopia.vn');
      expect(order.customerPhone, '0901234567');
      expect(order.address, '123 Đường Nguyễn Huệ, Quận 1, TP.HCM');
      expect(order.totalAmount, 245000.0);
      expect(order.status, OrderStatus.pending);
    });

    test('2. Tạo chuỗi itemsSummary chuẩn xác từ danh sách sản phẩm trong giỏ hàng', () {
      Cart.items.clear();
      Cart.items.add(CartItem(id: 'c1', product: sampleProduct1, quantity: 2));
      Cart.items.add(CartItem(id: 'c2', product: sampleProduct2, quantity: 3));

      final itemsSummary = Cart.items.map((i) => '${i.product.name} (x${i.quantity})').join(' + ');

      expect(itemsSummary, 'Táo Envy New Zealand (x2) + Xoài Cát Chu Cao Lãnh (x3)');
    });

    test('3. Đơn hàng mới tạo luôn có trạng thái ban đầu là Đang xử lý (OrderStatus.pending)', () {
      final order = Order(
        id: 'DH123456',
        customerName: 'Lê Thị Mai',
        address: '456 Lê Lợi, Đà Nẵng',
        totalAmount: 300000.0,
        createdAt: DateTime.now(),
      );

      expect(order.status, OrderStatus.pending);

      final json = order.toJson();
      expect(json['status'], 'Đang xử lý');
    });

    test('4. Serialization toJson và fromJson bảo toàn đúng thông tin và trạng thái đơn hàng', () {
      final original = Order(
        id: 'DH888999',
        customerName: 'Hoàng Minh',
        customerEmail: 'hoangminh@gmail.com',
        customerPhone: '0912999888',
        address: '789 Trần Hưng Đạo, Cần Thơ',
        totalAmount: 520000.0,
        itemsSummary: 'Sầu Riêng Ri6 (x2)',
        status: OrderStatus.pending,
        createdAt: DateTime.parse('2026-03-30T10:00:00Z'),
      );

      final json = original.toJson();
      expect(json['id'], 'DH888999');
      expect(json['customerName'], 'Hoàng Minh');
      expect(json['customerPhone'], '0912999888');
      expect(json['address'], '789 Trần Hưng Đạo, Cần Thơ');
      expect(json['totalAmount'], 520000.0);
      expect(json['status'], 'Đang xử lý');

      final reconstructed = Order.fromJson(json);
      expect(reconstructed.id, original.id);
      expect(reconstructed.customerName, original.customerName);
      expect(reconstructed.customerEmail, original.customerEmail);
      expect(reconstructed.customerPhone, original.customerPhone);
      expect(reconstructed.address, original.address);
      expect(reconstructed.totalAmount, original.totalAmount);
      expect(reconstructed.status, OrderStatus.pending);
      expect(reconstructed.itemsSummary, original.itemsSummary);
    });

    test('5. Quy trình hoàn tất tạo đơn: lưu đơn hàng và làm mới giỏ hàng (Cart.items.clear())', () {
      // 1. Giả lập giỏ hàng có 2 sản phẩm
      Cart.items.clear();
      Cart.items.add(CartItem(id: 'c1', product: sampleProduct1, quantity: 1));
      Cart.items.add(CartItem(id: 'c2', product: sampleProduct2, quantity: 2));
      expect(Cart.items.length, 2);
      expect(Cart.totalAmount, 180000 + (65000 * 2)); // 310,000₫

      // 2. Tạo đơn hàng từ thông tin giỏ hàng
      final summary = Cart.items.map((i) => '${i.product.name} (x${i.quantity})').join(' + ');
      final order = Order(
        id: 'DH_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'Trần Văn Hùng',
        customerEmail: 'hungtv@fruitopia.vn',
        customerPhone: '0901234567',
        address: '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
        totalAmount: Cart.totalAmount,
        itemsSummary: summary,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      // 3. Thêm vào danh sách quản lý đơn hàng
      DataService.orders.insert(0, order);
      expect(DataService.orders.length, 1);
      expect(DataService.orders.first.id, order.id);

      // 4. Giỏ hàng được dọn sạch sau khi đặt hàng thành công
      Cart.items.clear();
      expect(Cart.items, isEmpty);
      expect(Cart.totalAmount, 0.0);
    });
  });
}
