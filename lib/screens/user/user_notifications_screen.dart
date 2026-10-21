import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/order_notification_service.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final email = AuthService.userEmail;
    if (email == null || email.isEmpty) return;

    final notifications = OrderNotificationService.forCustomer(email);
    await OrderNotificationService.markAllRead(email);
    if (!mounted) return;
    setState(() => _notifications = notifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo đơn hàng')),
      body: AuthService.userEmail == null
          ? const Center(child: Text('Đăng nhập để xem thông báo đơn hàng.'))
          : _notifications.isEmpty
              ? const Center(child: Text('Bạn chưa có thông báo nào.'))
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final createdAt = DateTime.tryParse(
                      notification['createdAt']?.toString() ?? '',
                    )?.toLocal();
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.local_shipping_outlined),
                      ),
                      title: Text(notification['title']?.toString() ?? ''),
                      subtitle: Text(notification['message']?.toString() ?? ''),
                      trailing: createdAt == null
                          ? null
                          : Text(
                              '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                    );
                  },
                ),
    );
  }
}
