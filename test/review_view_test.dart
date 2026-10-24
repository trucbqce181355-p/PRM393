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
        id: 'p_cam_sanh',
        name: 'Cam Sành Tiền Giang',
        description: 'Cam sành mọng nước, nhiều vitamin C',
        price: 45000,
        unit: 'kg',
        imageUrl: '',
        rating: 5.0,
        stock: 60,
        category: 'Trái Cây Nhiệt Đới',
      ),
      Product(
        id: 'p_nho_mau_don',
        name: 'Nho Mẫu Đơn Shine Muscat',
        description: 'Nho mẫu đơn Nhật Bản quả to giòn ngọt',
        price: 520000,
        unit: 'chùm',
        imageUrl: '',
        rating: 5.0,
        stock: 30,
        category: 'Trái Cây Nhập Khẩu',
      ),
    ];
  });

  group('Quản lý đánh giá - Xem đánh giá sản phẩm Tests', () {
    test('1. Xem danh sách đánh giá của sản phẩm theo productId', () {
      final rev1 = Review(
        id: 'rev_01',
        productId: 'p_cam_sanh',
        productName: 'Cam Sành Tiền Giang',
        userName: 'Trần Văn Hùng',
        rating: 5,
        comment: 'Cam rất ngọt và nhiều nước, vắt nước uống tuyệt vời!',
        createdAt: DateTime.now(),
      );

      final rev2 = Review(
        id: 'rev_02',
        productId: 'p_nho_mau_don',
        productName: 'Nho Mẫu Đơn Shine Muscat',
        userName: 'Lê Thu Trang',
        rating: 5,
        comment: 'Nho thơm phức, quả to giòn sần sật.',
        createdAt: DateTime.now(),
      );

      DataService.reviews = [rev1, rev2];

      final camReviews = DataService.getReviewsForProduct('p_cam_sanh');
      expect(camReviews.length, 1);
      expect(camReviews.first.userName, 'Trần Văn Hùng');
      expect(camReviews.first.rating, 5);
      expect(camReviews.first.comment, contains('Cam rất ngọt'));
    });

    test('2. Xem danh sách đánh giá theo tên sản phẩm', () {
      final rev = Review(
        id: 'rev_03',
        productId: 'p_nho_mau_don',
        productName: 'Nho Mẫu Đơn Shine Muscat',
        userName: 'Nguyễn Hoàng Nam',
        rating: 4,
        comment: 'Nho ngon nhưng giá hơi cao một chút.',
        createdAt: DateTime.now(),
      );
      DataService.reviews = [rev];

      final results = DataService.getReviewsForProduct('', 'Nho Mẫu Đơn Shine Muscat');
      expect(results.length, 1);
      expect(results.first.userName, 'Nguyễn Hoàng Nam');
      expect(results.first.rating, 4);
    });

    test('3. Sản phẩm chưa có đánh giá nào trả về danh sách rỗng', () {
      DataService.reviews = [];
      final results = DataService.getReviewsForProduct('p_cam_sanh');
      expect(results, isEmpty);
    });

    test('4. Hiển thị chi tiết thời gian và thông tin người đánh giá', () {
      final reviewTime = DateTime.parse('2026-03-25 14:30:00');
      final rev = Review(
        id: 'rev_04',
        productId: 'p_cam_sanh',
        productName: 'Cam Sành Tiền Giang',
        userName: 'Võ Thị Mai',
        userEmail: 'maivo@gmail.com',
        rating: 5,
        comment: 'Giao hàng nhanh trong 2h, đóng thùng cẩn thận.',
        createdAt: reviewTime,
      );
      DataService.reviews = [rev];

      final results = DataService.getReviewsForProduct('p_cam_sanh');
      expect(results.first.userName, 'Võ Thị Mai');
      expect(results.first.userEmail, 'maivo@gmail.com');
      expect(results.first.createdAt, reviewTime);
    });
  });
}
