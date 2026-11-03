// Author: Chih An (GitHub: ChangChinAn)
// UC13–UC14: Dữ liệu địa chỉ và trạng thái địa chỉ giao hàng mặc định.
class DeliveryAddress {
  const DeliveryAddress({required this.id, required this.title, required this.address, required this.phone,
    this.isDefault = false});
  final String id;
  final String title;
  final String address;
  final String phone;
  final bool isDefault;
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => DeliveryAddress(
    id: json['id'] as String, title: json['title'] as String,
    address: json['address'] as String, phone: json['phone'] as String, isDefault: json['isDefault'] == true);
}
