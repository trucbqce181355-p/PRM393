class Voucher {
  final String code;
  final String description;
  final double discountAmount;
  final double minPurchase;
  final bool isActive;

  Voucher({
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.minPurchase,
    this.isActive = true,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: json['code'],
      description: json['description'],
      discountAmount: json['discountAmount'].toDouble(),
      minPurchase: json['minPurchase'].toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'discountAmount': discountAmount,
      'minPurchase': minPurchase,
      'isActive': isActive,
    };
  }

  Voucher copyWith({
    String? code,
    String? description,
    double? discountAmount,
    double? minPurchase,
    bool? isActive,
  }) {
    return Voucher(
      code: code ?? this.code,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      minPurchase: minPurchase ?? this.minPurchase,
      isActive: isActive ?? this.isActive,
    );
  }
}
