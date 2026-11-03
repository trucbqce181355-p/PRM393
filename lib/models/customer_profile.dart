// Author: Chih An (GitHub: ChangChinAn)
// UC11: Dữ liệu hồ sơ và hạng thành viên công khai trả về từ backend.
class CustomerProfile {
  const CustomerProfile({required this.id, required this.name, required this.email,
    required this.phone, required this.role, required this.memberTier,
    required this.totalSpent, required this.totalOrders});
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String memberTier;
  final double totalSpent;
  final int totalOrders;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
    id: json['id'] as String, name: json['name'] as String, email: json['email'] as String,
    phone: json['phone'] as String, role: json['role'] as String,
    memberTier: json['memberTier'] as String, totalSpent: (json['totalSpent'] as num).toDouble(),
    totalOrders: (json['totalOrders'] as num).toInt());
}
