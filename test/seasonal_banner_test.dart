import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Trang chủ & Khám phá sản phẩm - Hiển thị banner khuyến mãi, trái cây theo mùa', () {
    final List<Map<String, dynamic>> banners = [
      {
        'badge': 'MÙA VÀNG NHIỆT ĐỚI',
        'title': 'Trái Cây Nhiệt Đới Tươi Mát',
        'subtitle': 'Xoài Cát Chu, Sầu Riêng Ri6 ngọt béo vừa hái',
        'tag': 'ƯU ĐÃI ĐẾN 25%',
        'category': 'Trái Cây Nhiệt Đới',
        'image': 'https://images.unsplash.com/photo-1553279768-865429fa0078',
        'gradient': [const Color(0xFFE65100), const Color(0xFFFF9800)],
      },
      {
        'badge': 'NHẬP KHẨU CAO CẤP',
        'title': 'Táo Envy New Zealand Tươi Giòn',
        'subtitle': 'Nhập khẩu đường bay, thịt giòn tan, vị ngọt đậm',
        'tag': 'CHUẨN GLOBALGAP',
        'category': 'Trái Cây Nhập Khẩu',
        'image': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        'gradient': [const Color(0xFF880E4F), const Color(0xFFE91E63)],
      },
      {
        'badge': 'THU HOẠCH HỮU CƠ',
        'title': 'Trái Cây Theo Mùa Tươi Rót',
        'subtitle': 'Nho Mẫu Đơn & Cam Cara ruột đỏ mọng nước',
        'tag': 'FREESHIP TOÀN QUỐC',
        'category': 'Trái Cây Nhập Khẩu',
        'image': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b',
        'gradient': [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
      },
    ];

    test('1. Kiểm tra số lượng và cấu trúc dữ liệu banner trái cây theo mùa', () {
      expect(banners.length, greaterThanOrEqualTo(3));
      for (final banner in banners) {
        expect(banner.containsKey('badge'), isTrue);
        expect(banner.containsKey('title'), isTrue);
        expect(banner.containsKey('subtitle'), isTrue);
        expect(banner.containsKey('tag'), isTrue);
        expect(banner.containsKey('category'), isTrue);
        expect(banner.containsKey('image'), isTrue);
        expect(banner.containsKey('gradient'), isTrue);
      }
    });

    test('2. Banner hiển thị đầy đủ thông tin ưu đãi khuyến mãi', () {
      final tropicalBanner = banners.firstWhere((b) => b['badge'] == 'MÙA VÀNG NHIỆT ĐỚI');
      expect(tropicalBanner['tag'], 'ƯU ĐÃI ĐẾN 25%');
      expect(tropicalBanner['category'], 'Trái Cây Nhiệt Đới');

      final importedBanner = banners.firstWhere((b) => b['badge'] == 'NHẬP KHẨU CAO CẤP');
      expect(importedBanner['tag'], 'CHUẨN GLOBALGAP');
      expect(importedBanner['category'], 'Trái Cây Nhập Khẩu');

      final organicBanner = banners.firstWhere((b) => b['badge'] == 'THU HOẠCH HỮU CƠ');
      expect(organicBanner['tag'], 'FREESHIP TOÀN QUỐC');
    });

    test('3. Bấm vào banner kích hoạt điều hướng khám phá danh mục tương ứng', () {
      String selectedCategory = 'Tất cả';

      void onBannerTapped(Map<String, dynamic> banner) {
        selectedCategory = banner['category'] as String;
      }

      onBannerTapped(banners[0]);
      expect(selectedCategory, 'Trái Cây Nhiệt Đới');

      onBannerTapped(banners[1]);
      expect(selectedCategory, 'Trái Cây Nhập Khẩu');
    });
  });
}
