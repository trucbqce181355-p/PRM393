class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final String imageUrl;
  final double rating;
  int stock;
  final String category;
  final String origin;
  final String freshness;
  bool isActive;
  bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.imageUrl,
    this.rating = 5.0,
    this.stock = 100, // default stock
    this.category = 'Khác',
    this.origin = 'Việt Nam',
    this.freshness = '100% Tươi mới trong ngày',
    this.isActive = true,
    this.isDeleted = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'kg',
      imageUrl: json['imageUrl']?.toString() ?? '',
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
      'rating': rating,
      'stock': stock,
      'category': category,
      'origin': origin,
      'freshness': freshness,
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? unit,
    String? imageUrl,
    double? rating,
    int? stock,
    String? category,
    String? origin,
    String? freshness,
    bool? isActive,
    bool? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      origin: origin ?? this.origin,
      freshness: freshness ?? this.freshness,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
