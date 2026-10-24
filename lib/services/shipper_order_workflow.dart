import '../order_service.dart';

class ShipperOrderWorkflow {
  const ShipperOrderWorkflow._();

  static Future<bool> markAsDelivering(String orderId) {
    return OrderService.updateOrder(orderId, {
      'status': 'Đang giao',
      'shipperName': 'Shipper Demo',
      'acceptedAt': DateTime.now().toIso8601String(),
    });
  }
}
