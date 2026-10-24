import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/data_service.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String _searchQuery = '';
  @override
  Widget build(BuildContext context) {
    final conversations = DataService.getAllConversations().where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.customerName.toLowerCase().contains(q) || c.customerEmail.toLowerCase().contains(q) || c.lastMessage.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Hội thoại CSKH'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hội thoại theo tên, email, tin nhắn...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: conversations.isEmpty
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${c.lastMessageTime.hour}:${c.lastMessageTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11)),
                        if (c.unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                            child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
