import 'package:flutter/material.dart';

class UserSupportChatScreen extends StatefulWidget {
  const UserSupportChatScreen({super.key});

  @override
  State<UserSupportChatScreen> createState() => _UserSupportChatScreenState();
}

class _UserSupportChatScreenState extends State<UserSupportChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Xin chào! Fruitopia có thể giúp gì cho bạn hôm nay?', 'isMe': false, 'time': '09:00 AM'},
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': _controller.text, 'isMe': true, 'time': 'Bây giờ'});
    });
    _controller.clear();
    
    // Mock auto-reply
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'Cảm ơn bạn đã liên hệ. Đội ngũ CSKH sẽ phản hồi bạn trong ít phút nữa.',
            'isMe': false,
            'time': 'Bây giờ'
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, color: Colors.green),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CSKH Fruitopia', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Thường trả lời trong 5 phút', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['text'], msg['isMe'], msg['time']);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.photo, color: Colors.green), onPressed: () {}),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
