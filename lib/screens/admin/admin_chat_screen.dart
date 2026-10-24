import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_message.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<ChatConversation> get _filteredConversations {
    final list = DataService.getAllConversations();
    if (_searchQuery.isEmpty) return list;
    return list.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.customerName.toLowerCase().contains(q) ||
          c.customerEmail.toLowerCase().contains(q) ||
          c.lastMessage.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _filteredConversations;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hỗ trợ & Chat trực tuyến', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc hội thoại theo tên, email, tin nhắn...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Conversation List
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có cuộc trò chuyện nào từ khách hàng',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final c = conversations[index];
                      final timeStr = '${c.lastMessageTime.hour.toString().padLeft(2, '0')}:${c.lastMessageTime.minute.toString().padLeft(2, '0')}';

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              radius: 22,
                              child: Text(
                                c.customerName.isNotEmpty ? c.customerName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ),
                            if (c.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text(
                                    '${c.unreadCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.customerName,
                                style: TextStyle(
                                  fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: c.unreadCount > 0 ? Colors.green : Colors.grey,
                                fontSize: 11,
                                fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.customerEmail,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.lastMessage,
                              style: TextStyle(
                                color: c.unreadCount > 0 ? Colors.black87 : Colors.grey.shade700,
                                fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: c.isClosed
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Đã đóng', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () {
                          _openChatDetail(c);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openChatDetail(ChatConversation conversation) {
    DataService.markMessagesAsRead(conversation.id, 'admin');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _AdminConversationDetailScreen(conversationId: conversation.id, customerName: conversation.customerName),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

class _AdminConversationDetailScreen extends StatefulWidget {
  final String conversationId;
  final String customerName;

  const _AdminConversationDetailScreen({required this.conversationId, required this.customerName});

  @override
  State<_AdminConversationDetailScreen> createState() => _AdminConversationDetailScreenState();
}

class _AdminConversationDetailScreenState extends State<_AdminConversationDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    DataService.markMessagesAsRead(widget.conversationId, 'admin');
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _sendMessage({String? customText, String? imagePath}) async {
    final text = customText ?? _msgController.text.trim();
    if (text.isEmpty && imagePath == null) return;

    if (customText == null) _msgController.clear();

    final newMsg = ChatMessage(
      id: 'msg_admin_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderEmail: 'support@fruitopia.vn',
      senderName: 'Quản trị viên (Admin)',
      senderRole: 'admin',
      message: text,
      imageUrl: imagePath,
      type: imagePath != null ? 'image' : 'text',
      createdAt: DateTime.now(),
      isRead: false,
    );

    await DataService.sendChatMessage(newMsg);
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked != null) {
        await _sendMessage(customText: 'Admin đã gửi ảnh sản phẩm', imagePath: picked.path);
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Không thể chọn ảnh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = DataService.getMessagesForConversation(widget.conversationId);
    final isClosed = DataService.closedConversations.contains(widget.conversationId.toLowerCase());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(widget.conversationId, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isClosed ? Icons.lock_open : Icons.lock_outline),
            tooltip: isClosed ? 'Mở lại hội thoại' : 'Đóng hội thoại',
            onPressed: () async {
              if (isClosed) {
                await DataService.reopenConversation(widget.conversationId);
                SnackbarHelper.showSuccess(context, 'Đã mở lại hội thoại');
              } else {
                await DataService.closeConversation(widget.conversationId);
                SnackbarHelper.showSuccess(context, 'Đã đóng hội thoại');
              }
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (ctx, index) {
                final m = messages[index];
                final isAdmin = m.senderRole == 'admin' || m.senderRole == 'bot';
                final timeStr = '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';

                return Align(
                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                        bottomRight: Radius.circular(isAdmin ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isAdmin ? Colors.white70 : Colors.green,
                          ),
                        ),
                        if (m.imageUrl != null) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: m.imageUrl!.startsWith('http')
                                ? Image.network(m.imageUrl!, height: 160, fit: BoxFit.cover)
                                : Image.file(File(m.imageUrl!), height: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                          ),
                        ],
                        if (m.fileName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf, color: isAdmin ? Colors.white : Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Text(m.fileName!, style: TextStyle(fontSize: 12, color: isAdmin ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        if (m.message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            m.message,
                            style: TextStyle(color: isAdmin ? Colors.white : Colors.black87, fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(color: isAdmin ? Colors.white70 : Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo, color: Colors.green),
                    onPressed: _pickImage,
                    tooltip: 'Gửi ảnh',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn phản hồi khách hàng...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                      tooltip: 'Gửi',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
