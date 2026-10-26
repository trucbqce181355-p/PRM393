class StockTransaction {
  final String id;
  final String productId;
  final String productName;
  final String type; // 'in' (nhập), 'out' (xuất), 'audit' (kiểm kê), 'damage' (hư hỏng)
  final int quantity;
  final int previousStock;
  final int newStock;
  final double? costPrice;
  final String? partner; // Nhà cung cấp hoặc người nhận
  final String reason;
  final DateTime createdAt;
  final String creatorName;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.costPrice,
    this.partner,
    required this.reason,
    required this.createdAt,
    this.creatorName = 'Admin',
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? json['product_id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? json['product_name']?.toString() ?? 'Sản phẩm',
      type: json['type']?.toString() ?? 'in',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      partner: json['partner']?.toString() ?? json['supplier']?.toString(),
      reason: json['reason']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      creatorName: json['creatorName']?.toString() ?? 'Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'costPrice': costPrice,
      'partner': partner,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'creatorName': creatorName,
    };
  }
}
