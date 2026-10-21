enum OrderStatus { pending, ready, delivering, completed, cancelled }

class Order {
  final String id;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String address;
  final double totalAmount;
  final String itemsSummary;
  OrderStatus status;
  final DateTime createdAt;
  String? shipperName;
  String? shipperPhone;
  String? cancelReason;

  Order({
    required this.id,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.address,
    required this.totalAmount,
    this.itemsSummary = '',
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.shipperName,
    this.shipperPhone,
    this.cancelReason,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    OrderStatus parseStatus(String? s) {
      if (s == null) return OrderStatus.pending;
      final lower = s.toLowerCase().trim();
      if (lower == 'ready' || lower == 'đã gói xong') return OrderStatus.ready;
      if (lower == 'delivering' || lower == 'đang giao') return OrderStatus.delivering;
      if (lower == 'completed' || lower == 'đã hoàn thành' || lower == 'hoàn thành') return OrderStatus.completed;
      if (lower == 'cancelled' || lower == 'đã hủy') return OrderStatus.cancelled;
      return OrderStatus.pending;
    }

    return Order(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Khách hàng',
      customerEmail: json['customerEmail']?.toString() ?? json['customer_email']?.toString() ?? json['userId']?.toString(),
      customerPhone: json['customerPhone']?.toString() ?? json['customer_phone']?.toString(),
      address: json['address']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      itemsSummary: json['itemsSummary']?.toString() ?? json['items']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      shipperName: json['shipperName']?.toString() ?? json['shipper_name']?.toString(),
      shipperPhone: json['shipperPhone']?.toString() ?? json['shipper_phone']?.toString(),
      cancelReason: json['cancelReason']?.toString() ?? json['cancel_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String statusString;
    switch (status) {
      case OrderStatus.ready:
        statusString = 'Đã gói xong';
        break;
      case OrderStatus.delivering:
        statusString = 'Đang giao';
        break;
      case OrderStatus.completed:
        statusString = 'Đã hoàn thành';
        break;
      case OrderStatus.cancelled:
        statusString = 'Đã hủy';
        break;
      case OrderStatus.pending:
        statusString = 'Đang xử lý';
        break;
    }

    return {
      'id': id,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'address': address,
      'totalAmount': totalAmount,
      'itemsSummary': itemsSummary,
      'status': statusString,
      'createdAt': createdAt.toIso8601String(),
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'cancelReason': cancelReason,
    };
  }
}
