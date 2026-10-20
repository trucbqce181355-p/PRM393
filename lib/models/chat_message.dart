class ChatMessage {
  final String id;
  final String conversationId;
  final String senderEmail;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;
  final String? imageUrl;
  final String? fileAttachment;
  final String? fileName;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderEmail,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.imageUrl,
    this.fileAttachment,
    this.fileName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderEmail: json['senderEmail']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'user',
      message: json['message']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      fileAttachment: json['fileAttachment']?.toString(),
      fileName: json['fileName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'fileAttachment': fileAttachment,
      'fileName': fileName,
    };
  }
}

class ChatConversation {
  final String conversationId;
  final String customerName;
  final String customerEmail;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isClosed;

  ChatConversation({
    required this.conversationId,
    required this.customerName,
    required this.customerEmail,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isClosed = false,
  });
}
