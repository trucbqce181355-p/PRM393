import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../utils/format_helper.dart';
import 'order_detail_screen.dart';
import 'user_returns_screen.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  String _selectedFilter = 'all'; // 'all', 'order', 'return', 'promo', 'system'

  List<AppNotification> get _filteredNotifications {
    final list = DataService.getNotificationsForUser(AuthService.userEmail);
    if (_selectedFilter == 'all') return list;
    return list.where((n) => n.type == _selectedFilter).toList();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_outlined;
      case 'return':
        return Icons.assignment_return_outlined;
      case 'promo':
        return Icons.card_giftcard_outlined;
      case 'system':
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order':
        return Colors.green;
      case 'return':
        return Colors.orange;
      case 'promo':
        return Colors.purple;
      case 'system':
      default:
        return Colors.blue;
    }
  }

  void _onNotificationTap(AppNotification notif) async {
    if (!notif.isRead) {
      await DataService.markNotificationRead(notif.id);
      setState(() {});
    }

    if (!mounted) return;

    if (notif.orderId != null && notif.orderId!.isNotEmpty) {
      if (notif.type == 'return') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserReturnsScreen()),
        );
      } else {
        Order? order;
        try {
          order = DataService.orders.firstWhere((o) => o.id == notif.orderId);
        } catch (_) {
          order = null;
        }

        if (order != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order!)),
          );
        }
      }
    }
  }

  void _markAllAsRead() async {
    await DataService.markAllNotificationsRead(AuthService.userEmail);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifs = _filteredNotifications;
    final unreadCount = DataService.getUnreadNotificationCount(AuthService.userEmail);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thông báo của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18, color: Colors.green),
              label: const Text('Đã đọc tất cả', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildFilterChip('all', 'Tất cả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('order', 'Đơn hàng'),
                  const SizedBox(width: 8),
                  _buildFilterChip('return', 'Đổi trả'),
                  const SizedBox(width: 8),
                  _buildFilterChip('promo', 'Khuyến mãi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('system', 'Hệ thống'),
                ],
              ),
            ),
          ),

          Expanded(
            child: notifs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          const Text(
                            'Hòm thư thông báo trống',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Các cập nhật về đơn hàng, shipper và đổi trả sẽ hiển thị tại đây.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      final icon = _getTypeIcon(n.type);
                      final color = _getTypeColor(n.type);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: n.isRead ? 0.5 : 2,
                        color: n.isRead ? Colors.white : Colors.green.shade50.withValues(alpha: 0.5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _onNotificationTap(n),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.body,
                                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            FormatHelper.formatDateTime(n.createdAt),
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                          ),
                                          if (n.orderId != null)
                                            Text(
                                              'Xem chi tiết ›',
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}
