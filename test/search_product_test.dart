import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  setUp(() {
    DataService.products = [
      Product(
        id: 'p_tao_envy',
        name: 'Táo Envy New Zealand',
        description: 'Táo Envy New Zealand nhập khẩu chính ngạch, vỏ đỏ ruby, thịt giòn ngọt.',
        price: 185000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        rating: 5.0,
        stock: 85,
        category: 'Trái Cây Nhập Khẩu',
        origin: 'New Zealand',
      ),
      Product(
        id: 'p_xoai_cat',
        name: 'Xoài Cát Chu Cao Lãnh',
        description: 'Xoài Cát Chu đặc sản Cao Lãnh - Đồng Tháp, thơm ngọt đậm đà.',
        price: 65000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078',
        rating: 4.9,
        stock: 120,
        category: 'Trái Cây Nhiệt Đới',
        origin: 'Đồng Tháp, Việt Nam',
      ),
      Product(
        id: 'p_sau_rieng',
        name: 'Sầu Riêng Ri6 Cơm Vàng Hạt Lép',
        description: 'Sầu riêng Ri6 miền Tây múi béo ngậy ngọt lịm.',
        price: 145000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1589139265215-d7293a1cf552',
        rating: 4.8,
        stock: 40,
        category: 'Trái Cây Nhiệt Đới',
        origin: 'Bến Tre, Việt Nam',
      ),
      Product(
        id: 'p_nho_mau_don',
        name: 'Nho Mẫu Đơn Shine Muscat',
        description: 'Nho Mẫu Đơn nhập khẩu Nhật Bản giòn ngọt không hạt.',
        price: 420000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f',
        rating: 5.0,
        stock: 25,
        category: 'Trái Cây Nhập Khẩu',
        origin: 'Nhật Bản',
      ),
      Product(
        id: 'p_thanh_long',
        name: 'Thanh Long Ruột Đỏ Hữu Cơ',
        description: 'Thanh Long ruột đỏ Bình Thuận tươi mát thanh nhiệt.',
        price: 45000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1527325678964-54921661f888',
        rating: 4.7,
        stock: 150,
        category: 'Trái Cây Nhiệt Đới',
        origin: 'Bình Thuận, Việt Nam',
      ),
    ];
  });

  group('Tìm kiếm & Bộ lọc - Tìm kiếm sản phẩm', () {
    List<Product> searchProducts(String query) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return DataService.products;
      return DataService.products.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.origin.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.price.toString().contains(q);
      }).toList();
    }

    test('1. Tìm kiếm sản phẩm theo tên chính xác và tên không dấu / một phần', () {
      final results = searchProducts('táo');
      expect(results.length, 1);
      expect(results.first.name, contains('Táo Envy'));
    });

    test('2. Tìm kiếm sản phẩm theo xuất xứ nguồn gốc', () {
      final results = searchProducts('New Zealand');
      expect(results.length, 1);
      expect(results.first.id, 'p_tao_envy');

      final resultsVN = searchProducts('Việt Nam');
      expect(resultsVN.length, 3); // Xoài Cát Chu, Sầu Riêng, Thanh Long
    });

    test('3. Tìm kiếm sản phẩm theo danh mục', () {
      final results = searchProducts('nhập khẩu');
      expect(results.length, 2); // Táo Envy và Nho Mẫu Đơn
    });

    test('4. Tìm kiếm sản phẩm theo mô tả sản phẩm', () {
      final results = searchProducts('hạt lép');
      expect(results.length, 1);
      expect(results.first.name, contains('Sầu Riêng Ri6'));
    });

    test('5. Tìm kiếm sản phẩm theo mức giá tiền', () {
      final results = searchProducts('420000');
      expect(results.length, 1);
      expect(results.first.name, contains('Nho Mẫu Đơn'));
    });

    test('6. Tìm kiếm với từ khóa không tồn tại trả về danh sách rỗng', () {
      final results = searchProducts('Dưa hấu Long An không có');
      expect(results.isEmpty, isTrue);
    });

    test('7. Khi xóa từ khóa tìm kiếm (chuỗi rỗng), hiển thị đầy đủ danh sách', () {
      final results = searchProducts('');
      expect(results.length, 5);
    });
  });
}
