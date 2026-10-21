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

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.password = '', // Accounts without a plaintext password cannot use a fallback credential.
    required this.phone,
    required this.totalSpent,
    required this.totalOrders,
    this.isActive = true,
    this.memberTier = 'Đồng',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] ?? 0,
      isActive: json['isActive'] ?? true,
      memberTier: json['memberTier'] ?? 'Đồng',
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
    };
  }
}
