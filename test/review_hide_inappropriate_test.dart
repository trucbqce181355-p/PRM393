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

  group('Quản lý đánh giá - Ẩn đánh giá không phù hợp Tests', () {
    test('1. Admin thực hiện ẩn đánh giá vi phạm tiêu chuẩn', () async {
      final rev = Review(
        id: 'rev_bad_01',
        productId: 'p_sau_rieng',
        productName: 'Sầu Riêng Ri6',
        userName: 'Spammer',
        rating: 1,
        comment: 'Quảng cáo cờ bạc lô đề...',
        isHidden: false,
        createdAt: DateTime.now(),
      );

      await DataService.addReview(rev);
      expect(DataService.reviews.first.isHidden, isFalse);

      // Admin ẩn đánh giá không phù hợp
      await DataService.toggleHideReview('rev_bad_01', true);

      final updated = DataService.reviews.firstWhere((r) => r.id == 'rev_bad_01');
      expect(updated.isHidden, isTrue);
    });

    test('2. Khách hàng thông thường không nhìn thấy đánh giá đã bị ẩn', () async {
      final normalRev = Review(
        id: 'rev_normal',
        productId: 'p_sau_rieng',
        userName: 'Khách Tốt',
        rating: 5,
        comment: 'Hàng chuẩn',
        isHidden: false,
        createdAt: DateTime.now(),
      );

      final hiddenRev = Review(
        id: 'rev_hidden_spam',
        productId: 'p_sau_rieng',
        userName: 'Khách Vi Phạm',
        rating: 1,
        comment: 'Bình luận thô tục',
        isHidden: true,
        createdAt: DateTime.now(),
      );

      DataService.reviews = [normalRev, hiddenRev];

      // Xem với tư cách người dùng bình thường (includeHidden = false mặc định)
      final publicReviews = DataService.getReviewsForProduct('p_sau_rieng');
      expect(publicReviews.length, 1);
      expect(publicReviews.first.id, 'rev_normal');

      // Xem với tư cách Admin (includeHidden = true)
      final adminReviews = DataService.getReviewsForProduct('p_sau_rieng', null, true);
      expect(adminReviews.length, 2);
    });

    test('3. Bỏ ẩn đánh giá khôi phục lại trạng thái hiển thị bình thường', () async {
      final rev = Review(
        id: 'rev_unhide',
        productId: 'p_sau_rieng',
        userName: 'Khách A',
        rating: 4,
        comment: 'Đánh giá bị ẩn nhầm',
        isHidden: true,
        createdAt: DateTime.now(),
      );
      await DataService.addReview(rev);

      // Bỏ ẩn
      await DataService.toggleHideReview('rev_unhide', false);

      final updated = DataService.reviews.firstWhere((r) => r.id == 'rev_unhide');
      expect(updated.isHidden, isFalse);
      expect(DataService.getReviewsForProduct('p_sau_rieng').length, 1);
    });
  });
}
