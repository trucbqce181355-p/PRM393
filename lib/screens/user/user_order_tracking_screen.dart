import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/order_notification_service.dart';
import '../../services/order_status_service.dart';

class UserOrderTrackingScreen extends StatefulWidget {
  const UserOrderTrackingScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  State<UserOrderTrackingScreen> createState() => _UserOrderTrackingScreenState();
}

class _UserOrderTrackingScreenState extends State<UserOrderTrackingScreen> {
  late Map<String, dynamic> _order;
  bool _isRefreshing = false;

  static const _steps = [
    (status: OrderStatus.pending, title: 'Đã tiếp nhận đơn hàng', icon: Icons.receipt_long_outlined),
    (status: OrderStatus.ready, title: 'Đơn hàng đã được chuẩn bị', icon: Icons.inventory_2_outlined),
    (status: OrderStatus.delivering, title: 'Shipper đang giao hàng', icon: Icons.local_shipping_outlined),
    (status: OrderStatus.completed, title: 'Đã giao hàng thành công', icon: Icons.check_circle_outline),
  ];

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final email = AuthService.userEmail;
    if (email == null || email.trim().isEmpty) return;

    setState(() => _isRefreshing = true);
    try {
      await DataService.refreshOrders();
      final customerOrders = DataService.getOrdersForCustomer(email);
      await OrderNotificationService.syncStatusChanges(
        userEmail: email,
        currentOrders: customerOrders,
      );

      final matches = customerOrders.where((order) => order.id == _order['id']?.toString());
      if (mounted && matches.isNotEmpty) {
        final latest = matches.first;
        setState(() {
          _order = {
            ..._order,
            ...latest.toJson(),
            'items': latest.itemsSummary,
            'totalAmount': latest.totalAmount,
            'customerName': latest.customerName,
            'phone': latest.customerPhone,
            'address': latest.address,
          };
        });
      }
    } catch (error) {
      debugPrint('Could not refresh order tracking: $error');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = Order.fromJson(_order).status;
    final currentIndex = _steps.indexWhere((step) => step.status == currentStatus);
    final isCancelled = currentStatus == OrderStatus.cancelled;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: const Text('Theo dõi đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cập nhật trạng thái',
            onPressed: _isRefreshing ? null : _refreshStatus,
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đơn hàng #${_order['id'] ?? ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      isCancelled ? 'Đơn hàng đã bị hủy' : OrderStatusService.labelFor(currentStatus),
                      style: TextStyle(
                        color: isCancelled ? Colors.red : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isRefreshing) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
            ),
            if (isCancelled)
              Card(
                color: Colors.red.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Đơn hàng này đã bị hủy nên quá trình giao hàng đã dừng.'),
                ),
              )
            else
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                  child: Column(
                    children: List.generate(_steps.length, (index) {
                      final step = _steps[index];
                      final isDone = currentIndex >= 0 && index < currentIndex;
                      final isCurrent = index == currentIndex;
                      final color = isDone || isCurrent ? Colors.green : Colors.grey.shade400;
                      final timestamp = _timestampFor(index);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Column(
                              children: [
                                Icon(isDone ? Icons.check_circle : step.icon, color: color, size: 24),
                                if (index < _steps.length - 1)
                                  Container(width: 2, height: 46, color: isDone ? Colors.green : Colors.grey.shade300),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step.title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: color)),
                                  if (timestamp != null) ...[
                                    const SizedBox(height: 4),
                                    Text(timestamp, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ] else if (isCurrent)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Trạng thái hiện tại', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            if ((_order['address']?.toString().trim().isNotEmpty ?? false))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: Colors.green),
                  title: const Text('Địa chỉ nhận hàng'),
                  subtitle: Text(_order['address'].toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _timestampFor(int index) {
    final key = switch (index) {
      0 => 'createdAt',
      1 => 'readyAt',
      2 => 'acceptedAt',
      3 => 'deliveredAt',
      _ => null,
    };
    if (key == null) return null;
    final value = DateTime.tryParse(_order[key]?.toString() ?? '');
    if (value == null) return null;
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
