class Review {
  final String id;
  final String productId;
  final String? productName;
  final String userName;
  final String? userEmail;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool hasImage;
  final String? orderId;

  Review({
    required this.id,
    required this.productId,
    this.productName,
    required this.userName,
    this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.hasImage = false,
    this.orderId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? 'rev_${DateTime.now().millisecondsSinceEpoch}',
      productId: json['productId']?.toString() ?? json['product_id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? json['product_name']?.toString(),
      userName: json['userName']?.toString() ?? json['user_name']?.toString() ?? json['name']?.toString() ?? 'Khách hàng',
      userEmail: json['userEmail']?.toString() ?? json['user_email']?.toString() ?? json['email']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      hasImage: json['hasImage'] == true,
      orderId: json['orderId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'hasImage': hasImage,
      'orderId': orderId,
    };
  }
}
