import 'package:flutter_test/flutter_test.dart';
import 'package:traicay/models/product.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  setUp(() {
    DataService.products = [
      Product(
        id: 'p_tao_envy',
        name: 'Táo Envy New Zealand',
        description: 'Táo Envy New Zealand nhập khẩu chính ngạch.',
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
        description: 'Xoài Cát Chu đặc sản Cao Lãnh - Đồng Tháp.',
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
        description: 'Sầu riêng Ri6 miền Tây chuẩn cơm vàng hạt lép.',
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
        description: 'Nho Mẫu Đơn Shine Muscat nhập khẩu Nhật Bản.',
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
        description: 'Thanh Long ruột đỏ Bình Thuận tươi mát.',
        price: 45000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1527325678964-54921661f888',
        rating: 4.7,
        stock: 150,
        category: 'Trái Cây Nhiệt Đới',
        origin: 'Bình Thuận, Việt Nam',
      ),
      Product(
        id: 'p_cam_cara',
        name: 'Cam Cara Ruột Đỏ Úc',
        description: 'Cam Cara nhập khẩu Úc ruột đỏ không hạt.',
        price: 110000,
        unit: 'kg',
        imageUrl: 'https://images.unsplash.com/photo-1547514701-42782101795e',
        rating: 4.9,
        stock: 60,
        category: 'Trái Cây Nhập Khẩu',
        origin: 'Australia (Úc)',
      ),
    ];
  });

  group('Tìm kiếm & Bộ lọc - Lọc sản phẩm theo giá, nguồn gốc, danh mục', () {
    List<Product> filterProducts({
      String selectedCategory = 'Tất cả',
      List<String> selectedOrigins = const [],
      List<String> selectedPriceRanges = const [],
    }) {
      return DataService.products.where((p) {
        // Lọc theo Danh mục
        bool matchesCategory = true;
        if (selectedCategory != 'Tất cả') {
          final catLower = selectedCategory.toLowerCase();
          final pCatLower = p.category.toLowerCase();
          if (selectedCategory == 'Trái Cây Nhiệt Đới') {
            matchesCategory = pCatLower.contains('nhiệt đới') || pCatLower.contains('việt nam');
          } else if (selectedCategory == 'Trái Cây Nhập Khẩu') {
            matchesCategory = pCatLower.contains('nhập khẩu');
          } else {
            matchesCategory = pCatLower.contains(catLower) || catLower.contains(pCatLower);
          }
        }

        // Lọc theo Nguồn gốc
        bool matchesOrigin = true;
        if (selectedOrigins.isNotEmpty) {
          matchesOrigin = false;
          final pOriginLower = p.origin.toLowerCase();
          final pCatLower = p.category.toLowerCase();
          for (String origin in selectedOrigins) {
            if (origin == 'Việt Nam (Nội địa)' || origin == 'Việt Nam') {
              if (pOriginLower.contains('việt nam') ||
                  pOriginLower.contains('đồng tháp') ||
                  pOriginLower.contains('bến tre') ||
                  pOriginLower.contains('bình thuận')) {
                matchesOrigin = true;
                break;
              }
            } else if (origin == 'Nhập khẩu') {
              if (!pOriginLower.contains('việt nam') || pCatLower.contains('nhập khẩu')) {
                matchesOrigin = true;
                break;
              }
            } else if (origin == 'Australia (Úc)' || origin == 'Úc') {
              if (pOriginLower.contains('úc') || pOriginLower.contains('australia')) {
                matchesOrigin = true;
                break;
              }
            } else if (pOriginLower.contains(origin.toLowerCase())) {
              matchesOrigin = true;
              break;
            }
          }
        }

        // Lọc theo Giá
        bool matchesPrice = true;
        if (selectedPriceRanges.isNotEmpty) {
          matchesPrice = false;
          for (String range in selectedPriceRanges) {
            if (range == 'Dưới 100.000₫' && p.price < 100000) matchesPrice = true;
            if (range == '100.000₫ - 200.000₫' && p.price >= 100000 && p.price <= 200000) matchesPrice = true;
            if (range == '200.000₫ - 500.000₫' && p.price >= 200000 && p.price <= 500000) matchesPrice = true;
            if (range == 'Trên 500.000₫' && p.price > 500000) matchesPrice = true;
          }
        }

        return matchesCategory && matchesOrigin && matchesPrice;
      }).toList();
    }

    test('1. Lọc sản phẩm theo mức giá: Dưới 100.000₫', () {
      final results = filterProducts(selectedPriceRanges: ['Dưới 100.000₫']);
      expect(results.length, 2); // Xoài Cát Chu (65k) và Thanh Long (45k)
      expect(results.every((p) => p.price < 100000), isTrue);
    });

    test('2. Lọc sản phẩm theo mức giá: 100.000₫ - 200.000₫', () {
      final results = filterProducts(selectedPriceRanges: ['100.000₫ - 200.000₫']);
      expect(results.length, 3); // Cam Cara Úc (110k), Sầu Riêng Ri6 (145k), Táo Envy (185k)
    });

    test('3. Lọc sản phẩm theo nguồn gốc: Việt Nam (Nội địa)', () {
      final results = filterProducts(selectedOrigins: ['Việt Nam (Nội địa)']);
      expect(results.length, 3); // Xoài Cát Chu, Sầu Riêng, Thanh Long
    });

    test('4. Lọc sản phẩm theo nguồn gốc: New Zealand', () {
      final results = filterProducts(selectedOrigins: ['New Zealand']);
      expect(results.length, 1);
      expect(results.first.name, contains('Táo Envy'));
    });

    test('5. Lọc sản phẩm theo nguồn gốc: Nhật Bản', () {
      final results = filterProducts(selectedOrigins: ['Nhật Bản']);
      expect(results.length, 1);
      expect(results.first.name, contains('Nho Mẫu Đơn'));
    });

    test('6. Lọc sản phẩm theo danh mục: Trái Cây Nhập Khẩu', () {
      final results = filterProducts(selectedCategory: 'Trái Cây Nhập Khẩu');
      expect(results.length, 3); // Táo Envy, Nho Mẫu Đơn, Cam Cara Úc
    });

    test('7. Lọc kết hợp 3 tiêu chí: Danh mục Trái Cây Nhập Khẩu + Nguồn gốc Úc + Giá 100k-200k', () {
      final results = filterProducts(
        selectedCategory: 'Trái Cây Nhập Khẩu',
        selectedOrigins: ['Australia (Úc)'],
        selectedPriceRanges: ['100.000₫ - 200.000₫'],
      );
      expect(results.length, 1);
      expect(results.first.name, contains('Cam Cara'));
    });
  });
}
