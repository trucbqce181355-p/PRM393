import '../models/order.dart';
import 'storage_service.dart';

class OrderNotificationService {
  const OrderNotificationService._();

  static String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Đang xử lý';
      case OrderStatus.ready:
        return 'Đã gói xong';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Đã hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static Future<void> notifyStatusChanged({
    required String orderId,
    required String? userEmail,
    required OrderStatus status,
  }) async {
    if (userEmail == null || userEmail.trim().isEmpty) return;

    await StorageService.addOrderNotification(userEmail, {
      'orderId': orderId,
      'title': 'Đơn hàng #$orderId đã cập nhật',
      'message': 'Trạng thái đơn hàng hiện tại: ${_statusLabel(status)}.',
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  static Future<void> syncStatusChanges({
    required String userEmail,
    required List<Order> currentOrders,
  }) async {
    final cachedOrders = StorageService.getOrders(userEmail: userEmail);
    final syncedOrders = <Map<String, dynamic>>[];

    for (final order in currentOrders) {
      final status = _statusLabel(order.status);
      final cached = cachedOrders.where((item) => item['id'] == order.id);
      final previous = cached.isEmpty ? null : cached.first;

      if (previous != null && previous['status'] != status) {
        await notifyStatusChanged(
          orderId: order.id,
          userEmail: userEmail,
          status: order.status,
        );
      }

      syncedOrders.add({
        ...?previous,
        'id': order.id,
        'status': status,
      });
    }

    final currentIds = currentOrders.map((order) => order.id).toSet();
    syncedOrders.addAll(
      cachedOrders.where((order) => !currentIds.contains(order['id'])),
    );

    await StorageService.saveOrders(syncedOrders, userEmail: userEmail);
  }

  static List<Map<String, dynamic>> forCustomer(String userEmail) {
    return StorageService.getOrderNotifications(userEmail);
  }

  static Future<void> markAllRead(String userEmail) {
    return StorageService.markOrderNotificationsRead(userEmail);
  }
}
