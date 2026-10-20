import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/data_service.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  @override
  Widget build(BuildContext context) {
    final conversations = DataService.getAllConversations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Hội thoại CSKH'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: conversations.isEmpty
          ? const Center(child: Text('Chưa có cuộc hội thoại hỗ trợ nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: conversations.length,
              itemBuilder: (ctx, index) {
                final c = conversations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(c.customerName.isNotEmpty ? c.customerName[0].toUpperCase() : 'U'),
                    ),
                    title: Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('${c.lastMessageTime.hour}:${c.lastMessageTime.minute.toString().padLeft(2, '0')}'),
                  ),
                );
              },
            ),
    );
  }
}
