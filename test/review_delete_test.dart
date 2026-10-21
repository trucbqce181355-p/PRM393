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

  group('Quản lý đánh giá - Xóa đánh giá sản phẩm Tests', () {
    test('1. Xóa đánh giá thành công theo reviewId', () async {
      final rev = Review(
        id: 'rev_del_01',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'Lê Minh',
        rating: 5,
        comment: 'Đánh giá cần xóa',
        createdAt: DateTime.now(),
      );

      await DataService.addReview(rev);
      expect(DataService.reviews.length, 1);

      await DataService.deleteReview('rev_del_01');
      expect(DataService.reviews, isEmpty);
      expect(DataService.getReviewsForProduct('p_sau_rieng'), isEmpty);
    });

    test('2. Xóa đánh giá cập nhật lại điểm rating trung bình của sản phẩm', () async {
      final rev1 = Review(
        id: 'r_keep',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User Tốt',
        rating: 5,
        comment: 'Tuyệt đỉnh',
        createdAt: DateTime.now(),
      );
      final rev2 = Review(
        id: 'r_delete',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'User Xấu',
        rating: 1,
        comment: 'Spam đánh giá xấu',
        createdAt: DateTime.now(),
      );

      await DataService.addReview(rev1);
      await DataService.addReview(rev2);

      // Điểm trung bình hiện tại: (5 + 1) / 2 = 3.0
      expect(DataService.products.first.rating, 3.0);

      // Xóa đánh giá xấu
      await DataService.deleteReview('r_delete');

      // Điểm sau khi xóa chỉ còn 1 đánh giá 5 sao -> rating = 5.0
      expect(DataService.products.first.rating, 5.0);
    });

    test('3. Xóa reviewId không tồn tại xử lý an toàn không gây lỗi hệ thống', () async {
      expect(
        () async => await DataService.deleteReview('rev_non_existent'),
        returnsNormally,
      );
    });
  });
}
