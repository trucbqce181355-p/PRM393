import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'review_screen.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  late List<Map<String, dynamic>> _allOrders;

  @override
  void initState() {
    super.initState();
    _allOrders = StorageService.getOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: 'Đang xử lý'),
                Tab(text: 'Đang giao'),
                Tab(text: 'Đã hoàn thành'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrderList(_allOrders.where((o) => o['status'] == 'Đang xử lý').toList()),
                  _buildOrderList(_allOrders.where((o) => o['status'] == 'Đang giao').toList()),
                  _buildOrderList(_allOrders.where((o) => o['status'] == 'Đã hoàn thành').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Đơn hàng #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      order['status'],
                      style: TextStyle(
                        color: order['status'] == 'Đã hoàn thành' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['items'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(order['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(color: Colors.grey)),
                    Text('\$ ${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (order['status'] == 'Đang giao') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Theo dõi vận chuyển', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ] else if (order['status'] == 'Đã hoàn thành') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewScreen(orderId: order['id']),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Đánh giá sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

}
