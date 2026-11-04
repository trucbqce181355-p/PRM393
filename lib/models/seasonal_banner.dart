import 'package:flutter/material.dart';

class SeasonalBanner {
  final String id;
  final String badge;
  final String title;
  final String subtitle;
  final String tag;
  final String category;
  final String image;
  final int colorStart;
  final int colorEnd;

  SeasonalBanner({
    required this.id,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.category,
    required this.image,
    this.colorStart = 0xFF1B5E20,
    this.colorEnd = 0xFF4CAF50,
  });

  factory SeasonalBanner.fromJson(Map<String, dynamic> json) {
    int parseColor(dynamic val, int defaultColor) {
      if (val == null) return defaultColor;
      if (val is int) return val;
      if (val is String) {
        return int.tryParse(val) ?? defaultColor;
      }
      return defaultColor;
    }

    return SeasonalBanner(
      id: json['id']?.toString() ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
      badge: json['badge']?.toString() ?? 'MÙA VÀNG NHIỆT ĐỚI',
      title: json['title']?.toString() ?? 'Trái Cây Tươi Mát',
      subtitle: json['subtitle']?.toString() ?? '',
      tag: json['tag']?.toString() ?? 'ƯU ĐÃI ĐẾN 25%',
      category: json['category']?.toString() ?? 'Tất cả',
      image: json['image']?.toString() ?? '',
      colorStart: parseColor(json['colorStart'], 0xFF1B5E20),
      colorEnd: parseColor(json['colorEnd'], 0xFF4CAF50),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badge': badge,
      'title': title,
      'subtitle': subtitle,
      'tag': tag,
      'category': category,
      'image': image,
      'colorStart': colorStart,
      'colorEnd': colorEnd,
    };
  }

  Map<String, dynamic> toHomeMap() {
    return {
      'id': id,
      'badge': badge,
      'title': title,
      'subtitle': subtitle,
      'tag': tag,
      'category': category,
      'image': image,
      'gradient': [Color(colorStart), Color(colorEnd)],
    };
  }

  SeasonalBanner copyWith({
    String? id,
    String? badge,
    String? title,
    String? subtitle,
    String? tag,
    String? category,
    String? image,
    int? colorStart,
    int? colorEnd,
  }) {
    return SeasonalBanner(
      id: id ?? this.id,
      badge: badge ?? this.badge,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tag: tag ?? this.tag,
      category: category ?? this.category,
      image: image ?? this.image,
      colorStart: colorStart ?? this.colorStart,
      colorEnd: colorEnd ?? this.colorEnd,
    );
  }
}
