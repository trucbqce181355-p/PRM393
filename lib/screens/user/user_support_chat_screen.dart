import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

class UserSupportChatScreen extends StatefulWidget {
  const UserSupportChatScreen({super.key});

  @override
  State<UserSupportChatScreen> createState() => _UserSupportChatScreenState();
}

class _UserSupportChatScreenState extends State<UserSupportChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _conversationId => AuthService.currentUser?.email ?? 'guest@fruitopia.vn';
  String get _customerName => AuthService.currentUser?.name ?? 'Khách hàng';

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final msg = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId,
      senderEmail: _conversationId,
      senderName: _customerName,
      senderRole: 'user',
      message: text,
      createdAt: DateTime.now(),
    );

    _msgController.clear();
    await DataService.sendChatMessage(msg);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final messages = DataService.chatMessages.where((m) => m.conversationId == _conversationId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ trực tuyến'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (ctx, index) {
                final m = messages[index];
                final isMe = m.senderRole == 'user';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green.shade600 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.message,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(hintText: 'Nhập tin nhắn hỗ trợ...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
