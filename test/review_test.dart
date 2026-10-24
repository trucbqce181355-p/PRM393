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
        id: 'p_tao_envy',
        name: 'Táo Envy New Zealand',
        description: 'Táo Envy tươi giòn',
        price: 185000,
        unit: 'kg',
        imageUrl: 'https://example.com/tao.jpg',
        rating: 5.0,
        stock: 50,
        category: 'Trái Cây Nhập Khẩu',
        origin: 'New Zealand',
        freshness: '100% Tươi',
      ),
    ];
  });

  group('Review System & Real User Synchronization Tests', () {
    test('Mock reviews (Nguyễn Văn A, Trần Thị B, Lê Văn C) are completely excluded', () {
      DataService.reviews = [
        Review(
          id: 'mock_1',
          productId: 'p_tao_envy',
          productName: 'Táo Envy New Zealand',
          userName: 'Nguyễn Văn A',
          rating: 5,
          comment: 'Dữ liệu ảo 1',
          createdAt: DateTime.now(),
        ),
        Review(
          id: 'mock_2',
          productId: 'p_tao_envy',
          productName: 'Táo Envy New Zealand',
          userName: 'Trần Thị B',
          rating: 4,
          comment: 'Dữ liệu ảo 2',
          createdAt: DateTime.now(),
        ),
        Review(
          id: 'mock_3',
          productId: 'p_tao_envy',
          productName: 'Táo Envy New Zealand',
          userName: 'Lê Văn C',
          rating: 5,
          comment: 'Dữ liệu ảo 3',
          createdAt: DateTime.now(),
        ),
      ];

      final reviews = DataService.getReviewsForProduct('p_tao_envy', 'Táo Envy New Zealand');
      expect(reviews, isEmpty, reason: 'Tất cả review ảo phải bị loại bỏ hoàn toàn');
    });

    test('Real review by Huế Trân Võ for Táo is saved and retrieved successfully', () async {
      final hueTranReview = Review(
        id: 'rev_huetran_1',
        productId: 'p_tao_envy',
        productName: 'Táo Envy New Zealand',
        userName: 'Huế Trân Võ',
        userEmail: 'huetran@gmail.com',
        rating: 5,
        comment: 'Táo Envy rất ngọt, giòn và tươi mới. Đóng gói rất kỹ càng!',
        createdAt: DateTime.now(),
        hasImage: true,
        orderId: 'DH1001',
      );

      DataService.reviews.add(hueTranReview);

      // Lấy theo ID
      final byId = DataService.getReviewsForProduct('p_tao_envy');
      expect(byId.length, 1);
      expect(byId.first.userName, 'Huế Trân Võ');
      expect(byId.first.rating, 5);
      expect(byId.first.hasImage, isTrue);

      // Lấy theo Tên sản phẩm
      final byName = DataService.getReviewsForProduct('', 'Táo Envy New Zealand');
      expect(byName.length, 1);
      expect(byName.first.comment, contains('Táo Envy rất ngọt'));

      // Khớp từ khóa 'Táo'
      final byTao = DataService.getReviewsForProduct('', 'Táo');
      expect(byTao.length, 1);
      expect(byTao.first.userName, 'Huế Trân Võ');
    });

    test('Review serialization to and from JSON works accurately', () {
      final original = Review(
        id: 'rev_test_123',
        productId: 'p_tao_envy',
        productName: 'Táo Envy New Zealand',
        userName: 'Huế Trân Võ',
        userEmail: 'huetran@gmail.com',
        rating: 5,
        comment: 'Sản phẩm tuyệt vời',
        createdAt: DateTime.parse('2026-10-18T10:00:00.000Z'),
        hasImage: true,
        orderId: 'DH888',
      );

      final json = original.toJson();
      expect(json['id'], 'rev_test_123');
      expect(json['userName'], 'Huế Trân Võ');
      expect(json['productName'], 'Táo Envy New Zealand');
      expect(json['rating'], 5);
      expect(json['hasImage'], isTrue);
      expect(json['orderId'], 'DH888');

      final parsed = Review.fromJson(json);
      expect(parsed.id, original.id);
      expect(parsed.userName, 'Huế Trân Võ');
      expect(parsed.rating, 5);
      expect(parsed.comment, 'Sản phẩm tuyệt vời');
      expect(parsed.hasImage, isTrue);
    });
  });
}
