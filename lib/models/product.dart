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
    this.isActive = true,
    this.isDeleted = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      unit: json['unit'],
      imageUrl: json['imageUrl'],
      rating: json['rating']?.toDouble() ?? 5.0,
      stock: json['stock'] ?? 100,
      category: json['category'] ?? 'Khác',
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
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }
}
