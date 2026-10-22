import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_message.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import 'user_returns_screen.dart';

class UserSupportChatScreen extends StatefulWidget {
  final String? initialOrderId;
  const UserSupportChatScreen({super.key, this.initialOrderId});

  @override
  State<UserSupportChatScreen> createState() => _UserSupportChatScreenState();
}

class _UserSupportChatScreenState extends State<UserSupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _pollingTimer;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String get _conversationId => AuthService.userEmail ?? 'guest@fruitopia.vn';
  String get _userName => AuthService.userName ?? 'Khách hàng';

  @override
  void initState() {
    super.initState();
    _markRead();
    // Khởi tạo tin nhắn chào nếu chưa có tin nhắn nào
    _checkInitialGreeting();

    // Timer realtime 2s để làm mới tin nhắn mới
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _checkInitialGreeting() {
    final existing = DataService.getMessagesForConversation(_conversationId);
    if (existing.isEmpty) {
      final welcomeMsg = ChatMessage(
        id: 'msg_init_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _conversationId,
        senderEmail: 'support@fruitopia.vn',
        senderName: 'CSKH Fruitopia',
        senderRole: 'admin',
        message: 'Xin chào $_userName! Fruitopia rất hân hạnh được hỗ trợ bạn. Bạn cần tư vấn chọn trái cây hay hỗ trợ đơn hàng nào ạ?',
        createdAt: DateTime.now(),
        isRead: true,
      );
      DataService.sendChatMessage(welcomeMsg);
    }
  }

  void _markRead() {
    DataService.markMessagesAsRead(_conversationId, 'user');
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
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

  Future<void> _sendMessage({String? customText, String? imageUrl, String? fileName, String type = 'text', String? orderId}) async {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty && imageUrl == null && fileName == null) return;

    if (customText == null) _controller.clear();

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId,
      senderEmail: _conversationId,
      senderName: _userName,
      senderRole: 'user',
      message: text,
      imageUrl: imageUrl,
      fileName: fileName,
      type: type,
      orderId: orderId,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await DataService.sendChatMessage(newMsg);
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        await _sendMessage(
          customText: 'Đã gửi một ảnh thực tế',
          imageUrl: picked.path,
          type: 'image',
        );
      }
    } catch (e) {
      if (mounted) SnackbarHelper.showError(context, 'Không thể chọn ảnh: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gửi ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Chụp ảnh thực tế'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendAttachmentSimulation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.orange),
              title: const Text('Gửi tệp: Hóa đơn điện tử VAT (.pdf)'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMessage(
                  customText: 'Hóa đơn bán lẻ điện tử Fruitopia',
                  fileName: 'Hoa_don_dien_tu_PRM_Fruit.pdf',
                  type: 'file',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified, color: Colors.blue),
              title: const Text('Gửi tệp: Chứng thư kiểm nghiệm VSATTP (.pdf)'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMessage(
                  customText: 'Chứng nhận chất lượng VietGAP & GlobalGAP',
                  fileName: 'Chung_nhan_VSATTP_VietGAP.pdf',
                  type: 'file',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCloseConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kết thúc cuộc trò chuyện?'),
        content: const Text('Bạn có chắc chắn muốn đóng phiên hỗ trợ này không? Bạn vẫn có thể nhắn tin lại bất cứ lúc nào.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DataService.closeConversation(_conversationId);
              setState(() {});
              if (mounted) {
                SnackbarHelper.showSuccess(context, 'Đã đóng phiên hỗ trợ');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đóng cuộc trò chuyện', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawMessages = DataService.getMessagesForConversation(_conversationId);
    final isClosed = DataService.closedConversations.contains(_conversationId.toLowerCase());

    final messages = _searchQuery.isEmpty
        ? rawMessages
        : rawMessages.where((m) => m.message.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm tin nhắn...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              )
            : Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: const Icon(Icons.support_agent, color: Colors.green, size: 26),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CSKH Fruitopia',
                          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isClosed ? 'Phiên đã đóng' : 'Đang trực tuyến • Phản hồi ngay',
                              style: TextStyle(
                                color: isClosed ? Colors.grey : Colors.green.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            tooltip: 'Tìm tin nhắn',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'close') {
                _confirmCloseConversation();
              } else if (val == 'reopen') {
                DataService.reopenConversation(_conversationId);
                setState(() {});
                SnackbarHelper.showSuccess(context, 'Đã mở lại cuộc trò chuyện');
              } else if (val == 'return') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReturnsScreen()));
              }
            },
            itemBuilder: (ctx) => [
              if (!isClosed)
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Kết thúc cuộc trò chuyện'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'reopen',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.green, size: 20),
                      SizedBox(width: 10),
                      Text('Mở lại trò chuyện'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'return',
                child: Row(
                  children: [
                    Icon(Icons.assignment_return_outlined, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text('Yêu cầu đổi trả sản phẩm'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Action Suggestion Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionChip(
                    icon: Icons.assignment_return_rounded,
                    label: 'Yêu cầu đổi trả',
                    color: Colors.deepOrange,
                    onTap: () {
                      _sendMessage(
                        customText: 'Tôi muốn yêu cầu đổi trả / khiếu nại chất lượng sản phẩm.',
                        type: 'return_request',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionChip(
                    icon: Icons.local_shipping_outlined,
                    label: 'Tra cứu đơn hàng',
                    color: Colors.blue,
                    onTap: () {
                      _sendMessage(
                        customText: 'Cho tôi hỏi tình trạng giao hàng của đơn hàng gần nhất.',
                        type: 'support_request',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionChip(
                    icon: Icons.eco_outlined,
                    label: 'Tư vấn quả tươi',
                    color: Colors.green,
                    onTap: () {
                      _sendMessage(
                        customText: 'Hôm nay Fruitopia có loại trái cây nhập khẩu nào mới về ngon nhất?',
                        type: 'support_request',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionChip(
                    icon: Icons.help_outline,
                    label: 'Chính sách bảo hành',
                    color: Colors.purple,
                    onTap: () {
                      _sendMessage(
                        customText: 'Fruitopia có cam kết đổi trả 100% trong 24 giờ không?',
                        type: 'support_request',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Message List
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isNotEmpty ? 'Không tìm thấy tin nhắn phù hợp' : 'Chưa có tin nhắn nào',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (ctx, index) {
                      final m = messages[index];
                      final isMe = m.senderRole == 'user';
                      return _buildMessageItem(m, isMe);
                    },
                  ),
          ),

          // Chat Closed Alert Banner
          if (isClosed)
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cuộc trò chuyện này đã được kết thúc.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      DataService.reopenConversation(_conversationId);
                      setState(() {});
                    },
                    child: const Text('Mở lại', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
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
                    icon: const Icon(Icons.image_outlined, color: Colors.green),
                    onPressed: _showImageOptions,
                    tooltip: 'Gửi ảnh',
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.blue),
                    onPressed: _sendAttachmentSimulation,
                    tooltip: 'Gửi tệp',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isClosed ? 'Nhập tin nhắn để tiếp tục trò chuyện...' : 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
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

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage m, bool isMe) {
    final timeStr = '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(12),
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                m.senderName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green),
              ),

            // Image display
            if (m.imageUrl != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: m.imageUrl!.startsWith('http')
                    ? Image.network(m.imageUrl!, height: 160, fit: BoxFit.cover)
                    : Image.file(
                        File(m.imageUrl!),
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                      ),
              ),
            ],

            // File attachment display
            if (m.fileName != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.green.shade700 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, color: isMe ? Colors.white : Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        m.fileName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Message text
            if (m.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                m.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Time & Read Status (Ticks)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
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
        ),
      ),
    );
  }
}
