import 'package:flutter/material.dart';

import '../../utils/format_helper.dart';

class UserOrderDetailsScreen extends StatelessWidget {
  const UserOrderDetailsScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'Đang xử lý';
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
    final amount = (order['totalAmount'] as num?)?.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: 'Đơn hàng #${order['id'] ?? ''}',
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(child: Text(status, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (createdAt != null)
                  Text(
                    '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          _section(
            title: 'Sản phẩm',
            child: Text(
              order['items']?.toString().trim().isNotEmpty == true
                  ? order['items'].toString()
                  : 'Chưa có thông tin sản phẩm',
              style: const TextStyle(height: 1.5),
            ),
          ),
          _section(
            title: 'Thông tin giao hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(Icons.person_outline, order['customerName']?.toString(), 'Khách hàng'),
                _detailRow(Icons.phone_outlined, order['phone']?.toString(), 'Số điện thoại'),
                _detailRow(Icons.location_on_outlined, order['address']?.toString(), 'Địa chỉ'),
              ],
            ),
          ),
          _section(
            title: 'Thanh toán',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng'),
                Text(
                  amount == null
                      ? (order['total']?.toString() ?? '—')
                      : FormatHelper.formatPrice(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String? value, String fallback) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(child: Text('$fallback: $text', style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
