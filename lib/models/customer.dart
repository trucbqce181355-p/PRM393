class Customer {
  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final double totalSpent;
  final int totalOrders;
  final bool isActive;
  final String memberTier; // Vàng, Bạc, Đồng...
  final String? googleId;
  final bool isGoogleLinked;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.password = '123456', // default
    required this.phone,
    required this.totalSpent,
    required this.totalOrders,
    this.isActive = true,
    this.memberTier = 'Đồng',
    this.googleId,
    this.isGoogleLinked = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '123456',
      phone: json['phone']?.toString() ?? '',
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
      memberTier: json['memberTier']?.toString() ?? 'Đồng',
      googleId: json['googleId']?.toString(),
      isGoogleLinked: json['isGoogleLinked'] == true || (json['googleId'] != null && json['googleId'].toString().isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'isActive': isActive,
      'memberTier': memberTier,
      'googleId': googleId,
      'isGoogleLinked': isGoogleLinked,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    double? totalSpent,
    int? totalOrders,
    bool? isActive,
    String? memberTier,
    String? googleId,
    bool? isGoogleLinked,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      isActive: isActive ?? this.isActive,
      memberTier: memberTier ?? this.memberTier,
      googleId: googleId ?? this.googleId,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
    );
  }
}
