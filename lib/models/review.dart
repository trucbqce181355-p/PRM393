class Review {
  final String id;
  final String productId;
  final String? productName;
  final String userName;
  final String? userEmail;
  int rating;
  String comment;
  final DateTime createdAt;
  bool hasImage;
  String? imageUrl;
  final String? orderId;
  String? adminReply;
  DateTime? adminReplyAt;
  bool isHidden;
  DateTime? updatedAt;

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
    this.imageUrl,
    this.orderId,
    this.adminReply,
    this.adminReplyAt,
    this.isHidden = false,
    this.updatedAt,
  });

  Review copyWith({
    String? id,
    String? productId,
    String? productName,
    String? userName,
    String? userEmail,
    int? rating,
    String? comment,
    DateTime? createdAt,
    bool? hasImage,
    String? imageUrl,
    String? orderId,
    String? adminReply,
    DateTime? adminReplyAt,
    bool? isHidden,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      hasImage: hasImage ?? this.hasImage,
      imageUrl: imageUrl ?? this.imageUrl,
      orderId: orderId ?? this.orderId,
      adminReply: adminReply ?? this.adminReply,
      adminReplyAt: adminReplyAt ?? this.adminReplyAt,
      isHidden: isHidden ?? this.isHidden,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      orderId: json['orderId']?.toString(),
      adminReply: json['adminReply']?.toString() ?? json['reply']?.toString(),
      adminReplyAt: json['adminReplyAt'] != null
          ? DateTime.tryParse(json['adminReplyAt'].toString())
          : null,
      isHidden: json['isHidden'] == true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
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
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (orderId != null) 'orderId': orderId,
      if (adminReply != null) 'adminReply': adminReply,
      if (adminReplyAt != null) 'adminReplyAt': adminReplyAt!.toIso8601String(),
      'isHidden': isHidden,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
