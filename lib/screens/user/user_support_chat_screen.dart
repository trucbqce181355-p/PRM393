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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = DataService.getMessagesForConversation(_conversationId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hỗ trợ trực tuyến', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Đang trực tuyến (Phản hồi < 2 phút)', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
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
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.message,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey.shade600),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                m.isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: m.isRead ? Colors.lightBlueAccent : Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    )
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
                IconButton(
                  icon: const Icon(Icons.photo_camera, color: Colors.blue),
                  tooltip: 'Gửi ảnh minh chứng',
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  tooltip: 'Gửi tệp đính kèm',
                  onPressed: () async {
                    final msg = ChatMessage(
                      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                      conversationId: _conversationId,
                      senderEmail: _conversationId,
                      senderName: _customerName,
                      senderRole: 'user',
                      message: '[Tệp đính kèm: hoa_don_traicay.pdf]',
                      fileAttachment: 'https://fruitopia.vn/docs/hoa_don_traicay.pdf',
                      fileName: 'hoa_don_traicay.pdf',
                      createdAt: DateTime.now(),
                    );
                    await DataService.sendChatMessage(msg);
                    setState(() {});
                  },
                  onPressed: () async {
                    final msg = ChatMessage(
                      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                      conversationId: _conversationId,
                      senderEmail: _conversationId,
                      senderName: _customerName,
                      senderRole: 'user',
                      message: '[Đã đính kèm ảnh sản phẩm]',
                      imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&q=80&w=400',
                      createdAt: DateTime.now(),
                    );
                    await DataService.sendChatMessage(msg);
                    setState(() {});
                  },
                ),
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
