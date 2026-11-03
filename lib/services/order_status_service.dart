import '../models/order.dart';
import 'mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class OrderStatusService {
  const OrderStatusService._();

  static String labelFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ready:
        return 'Đã gói xong';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Đã hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
      case OrderStatus.pending:
        return 'Đang xử lý';
    }
  }

  static Future<Order?> updateStatus({
    required List<Order> orders,
    required String orderId,
    required OrderStatus status,
    required Future<void> Function() saveOrders,
  }) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return null;

    final order = orders[index];
    final now = DateTime.now();
    order.status = status;
    final updates = <String, dynamic>{
      'status': labelFor(status),
      'updatedAt': now.toIso8601String(),
    };
    switch (status) {
      case OrderStatus.ready:
        order.readyAt = now;
        updates['readyAt'] = now.toIso8601String();
        break;
      case OrderStatus.delivering:
        order.acceptedAt = now;
        updates['acceptedAt'] = now.toIso8601String();
        break;
      case OrderStatus.completed:
        order.deliveredAt = now;
        updates['deliveredAt'] = now.toIso8601String();
        break;
      case OrderStatus.pending:
      case OrderStatus.cancelled:
        break;
    }
    await saveOrders();

    try {
      await MongoDBService.getCollection('orders').updateOne(
        mongo.where.eq('id', orderId),
        {'\$set': updates},
      );
    } catch (error) {
      print('MongoDB Error (updateOrderStatus): $error');
    }

    return order;
  }
}
