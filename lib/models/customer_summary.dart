// Author: Chih An (GitHub: ChangChinAn)
// UC17: Thông tin khách hàng dành cho màn hình danh sách của quản trị viên.
class CustomerSummary {
  const CustomerSummary({required this.id, required this.name, required this.email,
    required this.phone, required this.isActive, this.createdAt});
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final DateTime? createdAt;
  factory CustomerSummary.fromJson(Map<String, dynamic> json) => CustomerSummary(
    id: json['id'] as String, name: json['name'] as String, email: json['email'] as String,
    phone: json['phone'] as String, isActive: json['isActive'] as bool,
    createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String));
}
