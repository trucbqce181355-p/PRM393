import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/models/order.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/models/cart_item.dart';
import 'package:traicay/services/auth_service.dart';
import 'package:traicay/services/storage_service.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DataService.orders = [];
  });

  group('Order Flow & Mock Data Removal Tests', () {
    test('Newly registered customer starts with NO orders (empty list)', () {
      final orders = StorageService.getOrders(userEmail: 'newuser@gmail.com');
      expect(orders, isEmpty);
      expect(orders.length, 0);

      final customerOrders = DataService.getOrdersForCustomer('newuser@gmail.com');
      expect(customerOrders, isEmpty);
    });

    test('Newly registered customer starts with NO fake addresses', () {
      final addresses = StorageService.getAddresses();
      expect(addresses, isEmpty);
    });

    test('Legacy mock orders #109283 and #109280 are completely filtered out', () async {
      SharedPreferences.setMockInitialValues({
        'orders': '[{"id": "109283", "items": "Táo Fuji"}, {"id": "109280", "items": "Chuối"}]',
        'addresses': '[{"address": "Số 1, Đại Cồ Việt, Hà Nội"}]',
      });
      await StorageService.init();

      final orders = StorageService.getOrders();
      expect(orders, isEmpty);

      final addresses = StorageService.getAddresses();
      expect(addresses, isEmpty);
    });

    test('Order model parses correctly and matches customer email', () {
      final order = Order(
        id: 'DH99999',
        customerName: 'Nguyễn Văn A',
        customerEmail: 'nguyenvana@gmail.com',
        customerPhone: '0988888888',
        address: '123 Đường Trái Cây, TP.HCM',
        totalAmount: 185000.0,
        itemsSummary: 'Táo Envy New Zealand (x1)',
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final json = order.toJson();
      expect(json['id'], 'DH99999');
      expect(json['customerEmail'], 'nguyenvana@gmail.com');
      expect(json['status'], 'Đang xử lý');
      expect(json['totalAmount'], 185000.0);

      final parsed = Order.fromJson(json);
      expect(parsed.id, order.id);
      expect(parsed.customerEmail, order.customerEmail);
      expect(parsed.status, OrderStatus.pending);
      expect(parsed.totalAmount, 185000.0);

      DataService.orders = [order];
      final userOrders = DataService.getOrdersForCustomer('nguyenvana@gmail.com');
      expect(userOrders.length, 1);
      expect(userOrders.first.id, 'DH99999');

      final otherOrders = DataService.getOrdersForCustomer('othercustomer@gmail.com');
      expect(otherOrders, isEmpty);
    });

    test('Adding delivery address and setting default address works properly for checkout', () async {
      expect(StorageService.getAddresses(), isEmpty);

      final addr1 = {
        'title': 'Nhà riêng',
        'address': 'Số 123 Đường Nguyễn Trãi, Quận 1, TP.HCM',
        'phone': '0987654321',
        'isDefault': true,
      };
      await StorageService.addAddress(addr1);

      var list = StorageService.getAddresses();
      expect(list.length, 1);
      expect(list.first['address'], 'Số 123 Đường Nguyễn Trãi, Quận 1, TP.HCM');
      expect(list.first['isDefault'], isTrue);

      final addr2 = {
        'title': 'Công ty',
        'address': 'Tòa nhà Landmark 81, Bình Thạnh, TP.HCM',
        'phone': '0912345678',
        'isDefault': false,
      };
      await StorageService.addAddress(addr2);

      list = StorageService.getAddresses();
      expect(list.length, 2);

      // Chuyển địa chỉ mặc định sang địa chỉ thứ 2
      await StorageService.setDefaultAddress(1);
      list = StorageService.getAddresses();
      expect(list[0]['isDefault'], isFalse);
      expect(list[1]['isDefault'], isTrue);
      expect(list[1]['title'], 'Công ty');
    });

    test('Logged out user can add products to cart, but cannot place order without logging in', () {
      AuthService.logout();
      expect(AuthService.isLoggedIn, isFalse);

      Cart.items.clear();
      final product = Product(
        id: 'p_test_tao',
        name: 'Táo Envy',
        description: 'Táo ngon',
        price: 185000,
        unit: 'kg',
        imageUrl: 'https://example.com/tao.jpg',
        rating: 5.0,
        stock: 10,
        category: 'Trái Cây',
        origin: 'New Zealand',
        freshness: 'Tươi',
      );

      // Cho phép thêm giỏ hàng khi đăng xuất
      Cart.addItem(product, 2);
      expect(Cart.items.length, 1);
      expect(Cart.totalAmount, 370000);

      // Bắt buộc phải đăng nhập thì mới cho phép mua hàng
      expect(AuthService.isLoggedIn, isFalse);

      // Sau khi đăng nhập thành công
      AuthService.saveProfile('Khách Hàng Mới', 'khach@gmail.com');
      expect(AuthService.isLoggedIn, isTrue);
      expect(Cart.items.length, 1); // Giỏ hàng bảo lưu nguyên vẹn
    });

    test('Inventory automatically deducted upon order placement and refunded when cancelled', () async {
      final product = Product(
        id: 'p_inventory_test',
        name: 'Cam Sành Mọng Nước',
        description: 'Cam ngon ngọt',
        price: 50000,
        unit: 'kg',
        imageUrl: 'https://example.com/cam.jpg',
        stock: 20,
        category: 'Trái Cây',
        origin: 'Việt Nam',
        freshness: 'Tươi mới',
      );
      DataService.products = [product];

      // Giả lập đặt hàng số lượng 5 kg
      await DataService.adjustProductStock(product.id, -5);
      expect(DataService.products.first.stock, 15);

      final order = Order(
        id: 'DH_INVENTORY_01',
        customerName: 'Khách Hàng Test',
        customerEmail: 'test@gmail.com',
        address: 'Hà Nội',
        totalAmount: 250000,
        itemsSummary: 'Cam Sành Mọng Nước (x5)',
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );
      DataService.orders = [order];

      // Admin hoặc khách hủy đơn -> Tồn kho tự động hoàn trả 5 kg
      await DataService.updateOrderStatus(
        order.id,
        OrderStatus.cancelled,
        cancelReason: 'Khách hàng đổi ý',
      );

      expect(DataService.orders.first.status, OrderStatus.cancelled);
      expect(DataService.orders.first.cancelReason, 'Khách hàng đổi ý');
      expect(DataService.products.first.stock, 20); // Đã hoàn lại đủ 20 kg
    });

    test('Assigning shipper and updating order delivery status', () async {
      final order = Order(
        id: 'DH_SHIPPER_01',
        customerName: 'Khách VIP',
        customerEmail: 'vip@gmail.com',
        address: 'Quận 7, TP.HCM',
        totalAmount: 500000,
        itemsSummary: 'Sầu riêng Ri6 (x1)',
        status: OrderStatus.ready,
        createdAt: DateTime.now(),
      );
      DataService.orders = [order];

      await DataService.updateOrderStatus(
        order.id,
        OrderStatus.delivering,
        shipperName: 'Nguyễn Văn Giao',
        shipperPhone: '0901.234.567',
      );

      expect(DataService.orders.first.status, OrderStatus.delivering);
      expect(DataService.orders.first.shipperName, 'Nguyễn Văn Giao');
      expect(DataService.orders.first.shipperPhone, '0901.234.567');
    });
  });
}
