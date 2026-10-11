class Voucher {
  final String code;
  final String description;
  final double discountAmount; // Số tiền giảm cố định (nếu discountType == 'fixed')
  final double minPurchase;
  final bool isActive;
  final String discountType; // 'fixed' (tiền mặt) | 'percentage' (phần trăm)
  final double discountPercentage; // % giảm giá (nếu discountType == 'percentage')
  final double maxDiscountAmount; // Giảm tối đa (khi giảm theo %)

  Voucher({
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.minPurchase,
    this.isActive = true,
    this.discountType = 'fixed',
    this.discountPercentage = 0.0,
    this.maxDiscountAmount = 0.0,
  });

  double calculateDiscount(double orderAmount) {
    if (orderAmount < minPurchase) return 0.0;
    if (discountType == 'percentage') {
      double calculated = orderAmount * (discountPercentage / 100.0);
      if (maxDiscountAmount > 0 && calculated > maxDiscountAmount) {
        calculated = maxDiscountAmount;
      }
      return calculated;
    }
    return discountAmount > orderAmount ? orderAmount : discountAmount;
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    final rawPercent = (json['discountPercentage'] ?? json['discount_percent'] ?? 0.0).toDouble();
    final rawAmount = (json['discountAmount'] ?? json['discount_amount'] ?? 0.0).toDouble();

    // If discount_percent > 100 (e.g. 15000 VND), legacy MongoDB records stored VND amount in discount_percent
    final isLegacyVnd = rawAmount == 0.0 && rawPercent > 100;
    final effectiveAmount = isLegacyVnd ? rawPercent : rawAmount;
    final effectivePercent = isLegacyVnd ? 0.0 : rawPercent;

    final type = json['discountType']?.toString() ??
        (!isLegacyVnd && effectivePercent > 0 ? 'percentage' : 'fixed');

    return Voucher(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountAmount: effectiveAmount,
      minPurchase: (json['minPurchase'] ?? json['min_order_value'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      discountType: type,
      discountPercentage: effectivePercent,
      maxDiscountAmount: (json['maxDiscountAmount'] ?? json['max_discount'] ?? 0.0).toDouble(),
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
      'maxDiscountAmount': maxDiscountAmount,
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
    double? maxDiscountAmount,
  }) {
    return Voucher(
      code: code ?? this.code,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      minPurchase: minPurchase ?? this.minPurchase,
      isActive: isActive ?? this.isActive,
      discountType: discountType ?? this.discountType,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
    );
  }
}
