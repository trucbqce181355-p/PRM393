class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'order' | 'return' | 'promo' | 'system'
  final String? customerEmail;
  final String? orderId;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'system',
    this.customerEmail,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      customerEmail: json['customerEmail']?.toString() ?? json['customer_email']?.toString(),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'customerEmail': customerEmail,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
