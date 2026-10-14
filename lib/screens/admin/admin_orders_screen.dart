import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  void _changeOrderStatus(Order order, OrderStatus newStatus) {
    setState(() {
      order.status = newStatus;
    });
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Order ${order.id} status updated to ${newStatus.name}')),
    // );
  }

  void _assignShipper(Order order) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Shipper assigned for Order ${order.id}')),
    // );
    // Update status to delivering as part of Flow 6
    _changeOrderStatus(order, OrderStatus.delivering);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF252538),
        title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: DataService.orders.length,
        itemBuilder: (context, index) {
          final order = DataService.orders[index];
          return Card(
            color: const Color(0xFF252538),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đơn hàng #${order.id}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      _buildStatusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Khách hàng: ${order.customerName}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Địa chỉ: ${order.address}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Tổng cộng: \$ ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  
                  const Divider(color: Colors.grey, height: 32),
                  
                  // Action buttons based on status (Flow 6)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.status == OrderStatus.pending)
                        ElevatedButton(
                          onPressed: () => _changeOrderStatus(order, OrderStatus.ready),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Gói xong', style: TextStyle(color: Colors.white)),
                        ),
                      if (order.status == OrderStatus.ready)
                        ElevatedButton(
                          onPressed: () => _assignShipper(order),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('Gán Shipper', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; break;
      case OrderStatus.ready: color = Colors.blue; break;
      case OrderStatus.delivering: color = Colors.purple; break;
      case OrderStatus.completed: color = Colors.green; break;
      case OrderStatus.cancelled: color = Colors.red; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
