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
        id: 'p_bo_sap',
        name: 'Bơ Sáp Đắk Lắk',
        description: 'Bơ sáp dẻo quánh béo ngậy',
        price: 75000,
        unit: 'kg',
        imageUrl: '',
        rating: 5.0,
        stock: 50,
        category: 'Trái Cây Nhiệt Đới',
      ),
    ];
  });

  group('Quản lý đánh giá - Phản hồi đánh giá của khách hàng (Admin) Tests', () {
    test('1. Admin gửi phản hồi thành công tới đánh giá của khách hàng', () async {
      final customerReview = Review(
        id: 'rev_cust_reply',
        productId: 'p_bo_sap',
        productName: 'Bơ Sáp Đắk Lắk',
        userName: 'Đoàn Nhật Minh',
        userEmail: 'minhdoan@gmail.com',
        rating: 5,
        comment: 'Bơ rất dẻo và béo, sẽ tiếp tục ủng hộ shop!',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );

      await DataService.addReview(customerReview);
      expect(DataService.reviews.first.adminReply, isNull);

      // Admin phản hồi đánh giá
      const replyContent = 'Dạ Fruitopia cảm ơn anh Minh nhiều ạ! Chúc anh và gia đình ngon miệng!';
      await DataService.replyReview('rev_cust_reply', replyContent);

      final updated = DataService.reviews.firstWhere((r) => r.id == 'rev_cust_reply');
      expect(updated.adminReply, replyContent);
      expect(updated.adminReplyAt, isNotNull);
    });

    test('2. SerializationtoJson và fromJson bảo toàn phản hồi admin và thời gian phản hồi', () {
      final replyTime = DateTime.parse('2026-03-30 09:15:00');
      final original = Review(
        id: 'rev_rep_json',
        productId: 'p_bo_sap',
        productName: 'Bơ Sáp Đắk Lắk',
        userName: 'Huế Trân Võ',
        rating: 5,
        comment: 'Tuyệt vời',
        adminReply: 'Cảm ơn bạn đã tin tưởng Fruitopia!',
        adminReplyAt: replyTime,
        createdAt: DateTime.now(),
      );

      final json = original.toJson();
      expect(json['adminReply'], 'Cảm ơn bạn đã tin tưởng Fruitopia!');
      expect(json['adminReplyAt'], replyTime.toIso8601String());

      final parsed = Review.fromJson(json);
      expect(parsed.adminReply, 'Cảm ơn bạn đã tin tưởng Fruitopia!');
      expect(parsed.adminReplyAt, replyTime);
    });

    test('3. Phản hồi reviewId không tồn tại xử lý an toàn không gây exception', () async {
      expect(
        () async => await DataService.replyReview('rev_unknown', 'Phản hồi test'),
        returnsNormally,
      );
    });
  });
}
