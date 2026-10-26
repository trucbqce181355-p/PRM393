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
        id: 'p_dau_tay',
        name: 'Dâu Tây Đà Lạt',
        description: 'Dâu tây đỏ mọng chua ngọt thanh mát',
        price: 120000,
        unit: 'hộp',
        imageUrl: '',
        rating: 5.0,
        stock: 50,
        category: 'Trái Cây Đà Lạt',
      ),
    ];
  });

  group('Quản lý đánh giá - Tải ảnh lên trong đánh giá Tests', () {
    test('1. Tạo đánh giá có đính kèm ảnh chụp thực tế thành công', () async {
      const imageUrl = 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&w=600';
      final rev = Review(
        id: 'rev_img_01',
        productId: 'p_dau_tay',
        productName: 'Dâu Tây Đà Lạt',
        userName: 'Nguyễn Thị Bích',
        userEmail: 'bichnguyen@gmail.com',
        rating: 5,
        comment: 'Dâu tây to đều, tươi cuống xanh như hình đính kèm!',
        hasImage: true,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await DataService.addReview(rev);

      expect(DataService.reviews.first.hasImage, isTrue);
      expect(DataService.reviews.first.imageUrl, imageUrl);
    });

    test('2. Serialization và Deserialization bảo toàn trường ảnh (hasImage, imageUrl)', () {
      const testUrl = 'https://fruitopia.vn/uploads/reviews/dau_tay_real.jpg';
      final original = Review(
        id: 'rev_json_img',
        productId: 'p_dau_tay',
        productName: 'Dâu Tây Đà Lạt',
        userName: 'Huế Trân Võ',
        rating: 5,
        comment: 'Ảnh chụp cận cảnh hộp dâu',
        hasImage: true,
        imageUrl: testUrl,
        createdAt: DateTime.now(),
      );

      final json = original.toJson();
      expect(json['hasImage'], isTrue);
      expect(json['imageUrl'], testUrl);

      final parsed = Review.fromJson(json);
      expect(parsed.hasImage, isTrue);
      expect(parsed.imageUrl, testUrl);
    });

    test('3. Chỉnh sửa đánh giá bổ sung hình ảnh thực tế', () async {
      final initial = Review(
        id: 'rev_add_img',
        productId: 'p_dau_tay',
        productName: 'Dâu Tây Đà Lạt',
        userName: 'Trần Minh Tâm',
        rating: 5,
        comment: 'Chưa có ảnh lúc đầu',
        hasImage: false,
        createdAt: DateTime.now(),
      );
      await DataService.addReview(initial);
      expect(DataService.reviews.first.hasImage, isFalse);

      const uploadedUrl = 'https://fruitopia.vn/uploads/reviews/tam_dautay.jpg';
      await DataService.updateReview('rev_add_img', imageUrl: uploadedUrl, hasImage: true);

      final updated = DataService.reviews.firstWhere((r) => r.id == 'rev_add_img');
      expect(updated.hasImage, isTrue);
      expect(updated.imageUrl, uploadedUrl);
    });
  });
}
