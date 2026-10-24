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
        id: 'p_mang_cut',
        name: 'Măng Cụt Lái Thiêu',
        description: 'Măng cụt thơm ngon múi trắng ngần',
        price: 90000,
        unit: 'kg',
        imageUrl: '',
        rating: 5.0,
        stock: 35,
        category: 'Trái Cây Nhiệt Đới',
      ),
    ];
  });

  group('Quản lý đánh giá - Xem điểm đánh giá trung bình của sản phẩm Tests', () {
    test('1. Tính điểm trung bình chính xác từ nhiều đánh giá khác nhau (làm tròn 1 chữ số)', () async {
      // 3 đánh giá: 5 sao, 4 sao, 4 sao -> TB: (5+4+4)/3 = 4.333... -> 4.3
      await DataService.addReview(Review(
        id: 'r1',
        productId: 'p_mang_cut',
        userName: 'User 1',
        rating: 5,
        comment: 'Tốt',
        createdAt: DateTime.now(),
      ));
      await DataService.addReview(Review(
        id: 'r2',
        productId: 'p_mang_cut',
        userName: 'User 2',
        rating: 4,
        comment: 'Khá ngon',
        createdAt: DateTime.now(),
      ));
      await DataService.addReview(Review(
        id: 'r3',
        productId: 'p_mang_cut',
        userName: 'User 3',
        rating: 4,
        comment: 'Ổn áp',
        createdAt: DateTime.now(),
      ));

      final avg = DataService.getAverageRatingForProduct('p_mang_cut');
      expect(avg, 4.3);
    });

    test('2. Sản phẩm chưa có đánh giá nào trả về rating mặc định của sản phẩm', () {
      final avg = DataService.getAverageRatingForProduct('p_mang_cut');
      expect(avg, 5.0);
    });

    test('3. Đánh giá bị ẩn (isHidden = true) không được tính vào điểm trung bình', () async {
      // 1 đánh giá tốt 5 sao
      await DataService.addReview(Review(
        id: 'r_good',
        productId: 'p_mang_cut',
        userName: 'Khách Thật',
        rating: 5,
        comment: 'Măng cụt rất ngon',
        createdAt: DateTime.now(),
      ));

      // 1 đánh giá xấu bị ẩn vi phạm chính sách
      await DataService.addReview(Review(
        id: 'r_hidden',
        productId: 'p_mang_cut',
        userName: 'Khách Vi Phạm',
        rating: 1,
        comment: 'Chửi tục',
        isHidden: true,
        createdAt: DateTime.now(),
      ));

      // Chỉ tính đánh giá 5 sao hợp lệ -> avg = 5.0
      final avg = DataService.getAverageRatingForProduct('p_mang_cut');
      expect(avg, 5.0);
    });
  });
}
