// Author: Chih An (GitHub: ChangChinAn)
// UC15: Tin nhắn hỗ trợ và danh sách hội thoại dành cho quản trị viên.
class SupportMessage {
  const SupportMessage({required this.id, required this.senderName, required this.senderRole,
    required this.message, required this.createdAt});
  final String id;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;
  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: json['id'] as String, senderName: json['senderName'] as String? ?? '',
    senderRole: json['senderRole'] as String, message: json['message'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String));
}
class SupportConversation {
  const SupportConversation({required this.email, required this.lastMessage});
  final String email;
  final String lastMessage;
  factory SupportConversation.fromJson(Map<String, dynamic> json) => SupportConversation(
    email: json['conversationId'] as String, lastMessage: json['lastMessage'] as String? ?? '');
}
class SupportSnapshot {
  const SupportSnapshot({required this.messages, required this.conversations});
  final List<SupportMessage> messages;
  final List<SupportConversation> conversations;
  factory SupportSnapshot.fromJson(Map<String, dynamic> json) => SupportSnapshot(
    messages: (json['messages'] as List).map((item) => SupportMessage.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
    conversations: (json['conversations'] as List).map((item) => SupportConversation.fromJson(Map<String, dynamic>.from(item as Map))).toList());
}
