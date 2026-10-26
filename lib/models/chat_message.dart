class ChatMessage {
  final String id;
  final String conversationId;
  final String senderEmail;
  final String senderName;
  final String senderRole; // 'user', 'admin', 'bot'
  final String message;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final DateTime createdAt;
  bool isRead;
  final String? orderId;
  final String type; // 'text', 'image', 'file', 'support_request', 'return_request'

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderEmail,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
    this.type = 'text',
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderEmail,
    String? senderName,
    String? senderRole,
    String? message,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    DateTime? createdAt,
    bool? isRead,
    String? orderId,
    String? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: json['conversationId']?.toString() ?? json['customerEmail']?.toString() ?? 'default',
      senderEmail: json['senderEmail']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Người dùng',
      senderRole: json['senderRole']?.toString() ?? 'user',
      message: json['message']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
      orderId: json['orderId']?.toString(),
      type: json['type']?.toString() ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'orderId': orderId,
      'type': type,
    };
  }
}

class ChatConversation {
  final String id; // conversationId (typically customerEmail)
  final String customerEmail;
  final String customerName;
  final String? customerPhone;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isClosed;
  final bool isSupportAgentOnline;

  ChatConversation({
    required this.id,
    required this.customerEmail,
    required this.customerName,
    this.customerPhone,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isClosed = false,
    this.isSupportAgentOnline = true,
  });

  ChatConversation copyWith({
    String? id,
    String? customerEmail,
    String? customerName,
    String? customerPhone,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isClosed,
    bool? isSupportAgentOnline,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      customerEmail: customerEmail ?? this.customerEmail,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isClosed: isClosed ?? this.isClosed,
      isSupportAgentOnline: isSupportAgentOnline ?? this.isSupportAgentOnline,
    );
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Khách hàng',
      customerPhone: json['customerPhone']?.toString(),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isClosed: json['isClosed'] == true,
      isSupportAgentOnline: json['isSupportAgentOnline'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isClosed': isClosed,
      'isSupportAgentOnline': isSupportAgentOnline,
    };
  }
}
