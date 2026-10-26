import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/models/order.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DataService.reviews = [];
    DataService.products = [
      Product(
        id: 'p_sau_rieng',
        name: 'Sầu Riêng Ri6',
        description: 'Cơm vàng hạt lép béo ngậy',
        price: 150000,
        unit: 'kg',
        imageUrl: '',
        rating: 5.0,
        stock: 40,
        category: 'Trái Cây Nhiệt Đới',
      ),
      Product(
        id: 'p_kiwi_vang',
        name: 'Kiwi Vàng New Zealand',
        description: 'Kiwi ruột vàng ngọt ngào',
        price: 160000,
        unit: 'hộp',
        imageUrl: '',
        rating: 5.0,
        stock: 30,
        category: 'Trái Cây Nhập Khẩu',
      ),
    ];

    // Khách hàng hungtv@fruitopia.vn đã có đơn hàng mua Sầu Riêng Ri6
    DataService.orders = [
      Order(
        id: 'DH9001',
        customerName: 'Trần Văn Hùng',
        customerEmail: 'hungtv@fruitopia.vn',
        customerPhone: '0901234567',
        address: '123 Nguyễn Huệ, TP.HCM',
        totalAmount: 300000.0,
        itemsSummary: 'Sầu Riêng Ri6 (x2)',
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  });

  group('Quản lý đánh giá - Xác minh đơn hàng đã mua trước khi đánh giá Tests', () {
    test('1. Xác minh thành công khi khách hàng đã từng mua sản phẩm', () {
      final canReview = DataService.hasPurchasedProduct('hungtv@fruitopia.vn', 'p_sau_rieng');
      expect(canReview, isTrue);

      final canReviewByName = DataService.hasPurchasedProduct('hungtv@fruitopia.vn', '', 'Sầu Riêng Ri6');
      expect(canReviewByName, isTrue);
    });

    test('2. Từ chối xác minh khi khách hàng chưa từng mua sản phẩm đó', () {
      // Khách hàng chưa từng mua Kiwi Vàng
      final canReview = DataService.hasPurchasedProduct('hungtv@fruitopia.vn', 'p_kiwi_vang');
      expect(canReview, isFalse);
    });

    test('3. Từ chối xác minh khi email khách hàng hoàn toàn mới chưa có đơn hàng nào', () {
      final canReview = DataService.hasPurchasedProduct('newuser@gmail.com', 'p_sau_rieng');
      expect(canReview, isFalse);
    });

    test('4. Từ chối xác minh khi email truyền vào rỗng hoặc không hợp lệ', () {
      final canReviewEmpty = DataService.hasPurchasedProduct('', 'p_sau_rieng');
      expect(canReviewEmpty, isFalse);

      final canReviewSpaces = DataService.hasPurchasedProduct('   ', 'p_sau_rieng');
      expect(canReviewSpaces, isFalse);
    });
  });
}
