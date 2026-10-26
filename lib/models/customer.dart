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
  final String role;
  final bool hasPassword;
  final bool? profileCompleted;
  final String sessionProvider;
  final String? googleId;
  final bool isGoogleLinked;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.password = '', // default
    required this.phone,
    required this.totalSpent,
    required this.totalOrders,
    this.isActive = true,
    this.memberTier = 'Đồng',
    this.role = 'customer',
    this.hasPassword = false,
    this.profileCompleted,
    this.sessionProvider = 'password',
    this.googleId,
    this.isGoogleLinked = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: '',
      phone: json['phone']?.toString() ?? '',
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
      memberTier: json['memberTier']?.toString() ?? 'Đồng',
      role: json['role'] == 'admin' ? 'admin' : 'customer',
      hasPassword: json['hasPassword'] == true,
      profileCompleted: json['profileCompleted'] as bool?,
      sessionProvider: json['sessionProvider'] == 'google'
          ? 'google'
          : 'password',
      googleId: (json['supabaseUserId'] ?? json['googleId'])?.toString(),
      isGoogleLinked:
          json['isGoogleLinked'] == true ||
          (json['googleId'] != null && json['googleId'].toString().isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'isActive': isActive,
      'memberTier': memberTier,
      'role': role,
      'hasPassword': hasPassword,
      'sessionProvider': sessionProvider,
      if (profileCompleted != null) 'profileCompleted': profileCompleted,
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
    String? role,
    bool? hasPassword,
    bool? profileCompleted,
    String? sessionProvider,
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
      role: role ?? this.role,
      hasPassword: hasPassword ?? this.hasPassword,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      sessionProvider: sessionProvider ?? this.sessionProvider,
      googleId: googleId ?? this.googleId,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
    );
  }
}
