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
        rating: 3.0,
        stock: 40,
        category: 'Trái Cây Nhiệt Đới',
      ),
    ];
  });

  group('Quản lý đánh giá - Chỉnh sửa đánh giá sản phẩm Tests', () {
    test('1. Chỉnh sửa nội dung và số sao của đánh giá đã có', () async {
      final initialReview = Review(
        id: 'rev_edit_01',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'Huỳnh Tuấn Kiệt',
        userEmail: 'kiethuynh@gmail.com',
        rating: 3,
        comment: 'Hơi sượng một chút.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await DataService.addReview(initialReview);
      expect(DataService.reviews.first.rating, 3);
      expect(DataService.reviews.first.comment, 'Hơi sượng một chút.');

      // Thực hiện chỉnh sửa đánh giá
      await DataService.updateReview(
        'rev_edit_01',
        rating: 5,
        comment: 'Được shop đổi trái khác chín già béo ngậy rất tuyệt vời!',
      );

      final updated = DataService.reviews.firstWhere((r) => r.id == 'rev_edit_01');
      expect(updated.rating, 5);
      expect(updated.comment, 'Được shop đổi trái khác chín già béo ngậy rất tuyệt vời!');
      expect(updated.updatedAt, isNotNull);
    });

    test('2. Chỉnh sửa số sao tự động tính toán lại điểm rating trung bình của sản phẩm', () async {
      final rev1 = Review(
        id: 'rev_calc_1',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User A',
        rating: 2,
        comment: 'Chưa hài lòng',
        createdAt: DateTime.now(),
      );
      await DataService.addReview(rev1);
      expect(DataService.products.first.rating, 2.0);

      // Cập nhật lên 5 sao
      await DataService.updateReview('rev_calc_1', rating: 5);

      expect(DataService.products.first.rating, 5.0);
    });

    test('3. Chỉnh sửa reviewId không tồn tại xử lý an toàn không phát sinh lỗi', () async {
      expect(
        () async => await DataService.updateReview('rev_non_existent', rating: 4, comment: 'Test'),
        returnsNormally,
      );
    });
  });
}
