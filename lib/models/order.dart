import '../../models/product.dart';

enum OrderStatus { pending, ready, delivering, completed, cancelled }

class Order {
  final String id;
  final String customerName;
  final String address;
  final double totalAmount;
  OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.address,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });
}
