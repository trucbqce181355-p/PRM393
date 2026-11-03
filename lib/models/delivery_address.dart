// Author: Chih An (GitHub: ChangChinAn)
// UC13: Dữ liệu địa chỉ giao hàng trả về từ backend.
class DeliveryAddress {
  const DeliveryAddress({required this.id, required this.title, required this.address, required this.phone});
  final String id;
  final String title;
  final String address;
  final String phone;
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => DeliveryAddress(
    id: json['id'] as String, title: json['title'] as String,
    address: json['address'] as String, phone: json['phone'] as String);
}
