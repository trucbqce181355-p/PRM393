class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final String imageUrl;
  final double rating;
  int stock;
  String category;
  final String origin;
  final String freshness;
  List<String> images;
  bool isActive;
  bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.imageUrl,
    List<String>? images,
    this.rating = 5.0,
    this.stock = 100, // default stock
    this.category = 'Khác',
    this.origin = 'Việt Nam',
    this.freshness = '100% Tươi mới trong ngày',
    this.isActive = true,
    this.isDeleted = false,
  }) : images = images ?? (imageUrl.isNotEmpty ? [imageUrl] : []);

  factory Product.fromJson(Map<String, dynamic> json) {
    final img = json['imageUrl']?.toString() ?? '';
    List<String> imgList = [];
    if (json['images'] != null && json['images'] is List) {
      imgList = (json['images'] as List).map((e) => e.toString()).toList();
    }
    if (imgList.isEmpty && img.isNotEmpty) {
      imgList = [img];
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'kg',
      imageUrl: img.isNotEmpty ? img : (imgList.isNotEmpty ? imgList.first : ''),
      images: imgList,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      stock: (json['stock'] as num?)?.toInt() ?? 100,
      category: json['category']?.toString() ?? 'Khác',
      origin: json['origin']?.toString() ?? 'Việt Nam',
      freshness: json['freshness']?.toString() ?? '100% Tươi mới trong ngày',
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'stock': stock,
      'category': category,
      'origin': origin,
      'freshness': freshness,
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }
}
