class ReturnRequest {
  final String id;
  final String orderId;
  final String customerEmail;
  final String customerName;
  final String reason;
  final String description;
  final String? imageUrl;
  String status; // 'pending' | 'approved' | 'rejected' | 'cancelled'
  String? adminReply;
  final DateTime createdAt;
  DateTime? updatedAt;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.customerEmail,
    required this.customerName,
    required this.reason,
    required this.description,
    this.imageUrl,
    this.status = 'pending',
    this.adminReply,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? json['customer_email']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['customer_name']?.toString() ?? 'Khách hàng',
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      adminReply: json['adminReply']?.toString() ?? json['admin_reply']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'reason': reason,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'adminReply': adminReply,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ReturnRequest copyWith({
    String? id,
    String? orderId,
    String? customerEmail,
    String? customerName,
    String? reason,
    String? description,
    String? imageUrl,
    String? status,
    String? adminReply,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReturnRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerEmail: customerEmail ?? this.customerEmail,
      customerName: customerName ?? this.customerName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      adminReply: adminReply ?? this.adminReply,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
