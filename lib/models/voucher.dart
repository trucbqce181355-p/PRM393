class Voucher {
  final String code;
  final String description;
  final double discountAmount;
  final double minPurchase;
  final bool isActive;
  final String discountType; // 'fixed' | 'percentage'
  final double discountPercentage;

  double calculateDiscount(double orderAmount) {
    if (orderAmount < minPurchase) return 0.0;
    if (discountType == 'percentage') {
      return orderAmount * (discountPercentage / 100.0);
    }
    return discountAmount > orderAmount ? orderAmount : discountAmount;
  }

  Voucher({
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.minPurchase,
    this.isActive = true,
    this.discountType = 'fixed',
    this.discountPercentage = 0.0,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    final rawPercent = (json['discountPercentage'] ?? json['discount_percent'] ?? 0.0).toDouble();
    final rawAmount = (json['discountAmount'] ?? json['discount_amount'] ?? 0.0).toDouble();
    final isPercentage = json['discountType'] == 'percentage' || (rawPercent > 0 && rawPercent <= 100);

    return Voucher(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountAmount: isPercentage ? 0.0 : rawAmount,
      minPurchase: (json['minPurchase'] ?? json['min_order_value'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      discountType: isPercentage ? 'percentage' : 'fixed',
      discountPercentage: rawPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'discountAmount': discountAmount,
      'minPurchase': minPurchase,
      'isActive': isActive,
      'discountType': discountType,
      'discountPercentage': discountPercentage,
    };
  }

  Voucher copyWith({
    String? code,
    String? description,
    double? discountAmount,
    double? minPurchase,
    bool? isActive,
    String? discountType,
    double? discountPercentage,
  }) {
    return Voucher(
      code: code ?? this.code,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      minPurchase: minPurchase ?? this.minPurchase,
      isActive: isActive ?? this.isActive,
      discountType: discountType ?? this.discountType,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}
