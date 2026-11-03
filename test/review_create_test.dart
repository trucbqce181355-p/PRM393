import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/models/review.dart';
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
    ];
  });

  group('Quản lý đánh giá - Tạo đánh giá sản phẩm Tests', () {
    test('1. Tạo mới đánh giá với đầy đủ thông tin: sao (1-5), nhận xét, người đánh giá', () async {
      final review = Review(
        id: 'rev_create_01',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'Ngô Thanh Vân',
        userEmail: 'vanngo@gmail.com',
        rating: 5,
        comment: 'Sầu riêng chín tới, múi khô ráo béo ngậy cực kỳ ngon!',
        createdAt: DateTime.now(),
      );

      await DataService.addReview(review);

      expect(DataService.reviews.length, 1);
      final saved = DataService.reviews.first;
      expect(saved.id, 'rev_create_01');
      expect(saved.rating, 5);
      expect(saved.userName, 'Ngô Thanh Vân');
      expect(saved.userEmail, 'vanngo@gmail.com');
      expect(saved.comment, contains('múi khô ráo'));
    });

    test('2. Đánh giá mới nhất luôn được đưa lên đầu danh sách (LIFO)', () async {
      final rev1 = Review(
        id: 'rev_first',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User 1',
        rating: 4,
        comment: 'Đánh giá đầu tiên',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      final rev2 = Review(
        id: 'rev_latest',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User 2',
        rating: 5,
        comment: 'Đánh giá mới nhất vừa xong',
        createdAt: DateTime.now(),
      );

      await DataService.addReview(rev1);
      await DataService.addReview(rev2);

      expect(DataService.reviews.first.id, 'rev_latest');
      expect(DataService.reviews.last.id, 'rev_first');
    });

    test('3. Tạo đánh giá tự động cập nhật điểm sao trung bình của sản phẩm', () async {
      final rev1 = Review(
        id: 'r1',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User A',
        rating: 4,
        comment: 'Ngon',
        createdAt: DateTime.now(),
      );
      await DataService.addReview(rev1);

      expect(DataService.products.first.rating, 4.0);

      final rev2 = Review(
        id: 'r2',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User B',
        rating: 5,
        comment: 'Rất tuyệt vời',
        createdAt: DateTime.now(),
      );
      await DataService.addReview(rev2);

      // (4 + 5) / 2 = 4.5
      expect(DataService.products.first.rating, 4.5);
    });
  });
}
