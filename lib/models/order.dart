enum OrderStatus {
  pending,
  ready,
  delivering,
  completed,
  cancelled,
}

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

  // Chi tiết hóa đơn và giao hàng
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final String shippingMethod;
  final double shippingFee;
  final double discountAmount;
  final String? voucherCode;
  String? assignedShipperName;
  String? assignedShipperPhone;
  final String? deliveryNotes;
  String? cancellationReason;

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
    this.items = const [],
    this.paymentMethod = 'COD',
    this.shippingMethod = 'STANDARD',
    this.shippingFee = 0.0,
    this.discountAmount = 0.0,
    this.voucherCode,
    String? assignedShipperName,
    String? assignedShipperPhone,
    this.deliveryNotes,
    String? cancellationReason,
    String? shipperName,
    String? shipperPhone,
    String? cancelReason,
  })  : assignedShipperName = assignedShipperName ?? shipperName,
        assignedShipperPhone = assignedShipperPhone ?? shipperPhone,
        cancellationReason = cancellationReason ?? cancelReason,
        shipperName = shipperName ?? assignedShipperName,
        shipperPhone = shipperPhone ?? assignedShipperPhone,
        cancelReason = cancelReason ?? cancellationReason;

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

    List<Map<String, dynamic>> parseItems(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }

    final sName = json['assignedShipperName']?.toString() ?? json['shipperName']?.toString() ?? json['shipper_name']?.toString();
    final sPhone = json['assignedShipperPhone']?.toString() ?? json['shipperPhone']?.toString() ?? json['shipper_phone']?.toString();
    final cReason = json['cancellationReason']?.toString() ?? json['cancelReason']?.toString() ?? json['cancel_reason']?.toString();

    return Order(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Khách hàng',
      customerEmail: json['customerEmail']?.toString() ?? json['customer_email']?.toString() ?? json['userId']?.toString(),
      customerPhone: json['customerPhone']?.toString() ?? json['customer_phone']?.toString(),
      address: json['address']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      itemsSummary: json['itemsSummary']?.toString() ?? json['items_summary']?.toString() ?? json['items']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parseItems(json['orderItems'] ?? json['cart_items']),
      paymentMethod: json['paymentMethod']?.toString() ?? json['payment_method']?.toString() ?? 'COD',
      shippingMethod: json['shippingMethod']?.toString() ?? json['shipping_method']?.toString() ?? 'STANDARD',
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      voucherCode: json['voucherCode']?.toString(),
      assignedShipperName: sName,
      assignedShipperPhone: sPhone,
      shipperName: sName,
      shipperPhone: sPhone,
      deliveryNotes: json['deliveryNotes']?.toString() ?? json['notes']?.toString(),
      cancellationReason: cReason,
      cancelReason: cReason,
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
      default:
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
      'orderItems': items,
      'paymentMethod': paymentMethod,
      'shippingMethod': shippingMethod,
      'shippingFee': shippingFee,
      'discountAmount': discountAmount,
      'voucherCode': voucherCode,
      'assignedShipperName': assignedShipperName,
      'assignedShipperPhone': assignedShipperPhone,
      'shipperName': shipperName,
      'shipperPhone': shipperPhone,
      'deliveryNotes': deliveryNotes,
      'cancellationReason': cancellationReason,
      'cancelReason': cancelReason,
    };
  }

  Order copyWith({
    String? id,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? address,
    double? totalAmount,
    String? itemsSummary,
    OrderStatus? status,
    DateTime? createdAt,
    List<Map<String, dynamic>>? items,
    String? paymentMethod,
    String? shippingMethod,
    double? shippingFee,
    double? discountAmount,
    String? voucherCode,
    String? assignedShipperName,
    String? assignedShipperPhone,
    String? deliveryNotes,
    String? cancellationReason,
    String? shipperName,
    String? shipperPhone,
    String? cancelReason,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      totalAmount: totalAmount ?? this.totalAmount,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippingFee: shippingFee ?? this.shippingFee,
      discountAmount: discountAmount ?? this.discountAmount,
      voucherCode: voucherCode ?? this.voucherCode,
      assignedShipperName: assignedShipperName ?? shipperName ?? this.assignedShipperName,
      assignedShipperPhone: assignedShipperPhone ?? shipperPhone ?? this.assignedShipperPhone,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      cancellationReason: cancellationReason ?? cancelReason ?? this.cancellationReason,
      shipperName: shipperName ?? assignedShipperName ?? this.shipperName,
      shipperPhone: shipperPhone ?? assignedShipperPhone ?? this.shipperPhone,
      cancelReason: cancelReason ?? cancellationReason ?? this.cancelReason,
    );
  }
}
