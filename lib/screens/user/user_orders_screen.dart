import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../models/order.dart';
import '../../utils/format_helper.dart';
import 'order_detail_screen.dart';
import 'review_screen.dart';
import 'user_home_screen.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserOrders();
  }

  void _openOrderDetail(String orderId) {
    Order? order;
    try {
      order = DataService.orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      order = null;
    }

    if (order == null) {
      final map = _allOrders.firstWhere((o) => o['id'] == orderId, orElse: () => {});
      order = Order(
        id: orderId,
        customerName: AuthService.userName ?? 'Khách hàng',
        customerEmail: AuthService.userEmail,
        address: map['address']?.toString() ?? 'Địa chỉ trong hệ thống',
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
        itemsSummary: map['items']?.toString() ?? '',
        createdAt: DateTime.now(),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order!)),
    ).then((_) => _loadUserOrders());
  }

  Future<void> _loadUserOrders() async {
    setState(() => _isLoading = true);

    // Đồng bộ đơn hàng mới nhất từ MongoDB traicay_db
    await DataService.refreshOrders();

    final userEmail = AuthService.userEmail;
    final List<Map<String, dynamic>> loaded = [];

    // 1. Lấy từ DataService (đã sync với MongoDB traicay_db)
    final dbOrders = DataService.getOrdersForCustomer(userEmail);
    for (var o in dbOrders) {
      loaded.add({
        'id': o.id,
        'status': o.toJson()['status'] ?? 'Đang xử lý',
        'items': o.itemsSummary.isNotEmpty ? o.itemsSummary : 'Sản phẩm trái cây',
        'date': '${o.createdAt.day.toString().padLeft(2, '0')}/${o.createdAt.month.toString().padLeft(2, '0')}/${o.createdAt.year} ${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}',
        'total': FormatHelper.formatPrice(o.totalAmount),
        'totalAmount': o.totalAmount,
      });
    }

    // 2. Dự phòng lấy từ StorageService cục bộ
    final localOrders = StorageService.getOrders(userEmail: userEmail);
    for (var local in localOrders) {
      if (!loaded.any((o) => o['id'] == local['id'])) {
        loaded.add(local);
      }
    }

    if (mounted) {
      setState(() {
        _allOrders = loaded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _allOrders.isEmpty
              ? _buildEmptyOrdersView()
              : RefreshIndicator(
                  color: Colors.green,
                  onRefresh: _loadUserOrders,
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: const TabBar(
                            labelColor: Colors.green,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.green,
                            indicatorWeight: 3,
                            tabs: [
                              Tab(text: 'Đang xử lý'),
                              Tab(text: 'Đang giao'),
                              Tab(text: 'Đã hoàn thành'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildOrderList(_allOrders.where((o) => o['status'] == 'Đang xử lý').toList(), 'Chưa có đơn hàng nào đang xử lý'),
                              _buildOrderList(_allOrders.where((o) => o['status'] == 'Đang giao' || o['status'] == 'Đã gói xong').toList(), 'Chưa có đơn hàng nào đang giao'),
                              _buildOrderList(_allOrders.where((o) => o['status'] == 'Đã hoàn thành').toList(), 'Chưa có đơn hàng nào đã hoàn thành'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 54,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tài khoản của bạn hiện chưa có lịch sử mua hàng.\nHãy chọn mua những loại trái cây tươi ngon ngay nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              label: const Text(
                'Khám phá trái cây ngay',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(emptyMsg, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = order['status']?.toString() ?? 'Đang xử lý';
        final isCompleted = status == 'Đã hoàn thành';
        final isDelivering = status == 'Đang giao' || status == 'Đã gói xong';

        final orderId = order['id']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openOrderDetail(orderId),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đơn hàng #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade50
                              : (isDelivering ? Colors.blue.shade50 : Colors.orange.shade50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.green
                                : (isDelivering ? Colors.blue : Colors.orange),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag, color: Colors.green, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['items'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(order['date'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(
                        order['total']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openOrderDetail(orderId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text('Xem chi tiết', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      if (isDelivering) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openOrderDetail(orderId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.local_shipping, size: 16),
                            label: const Text('Theo dõi vận chuyển', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ] else if (isCompleted) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewScreen(
                                    orderId: orderId,
                                    productName: order['items']?.toString() ?? '',
                                  ),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  _loadUserOrders();
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.star_outline, size: 16),
                            label: const Text('Đánh giá', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

