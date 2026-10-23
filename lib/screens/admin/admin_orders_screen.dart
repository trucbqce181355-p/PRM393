import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';
import '../user/order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  OrderStatus? _selectedStatusFilter; // null = Tất cả

  final List<Map<String, String>> _availableShippers = [
    {'name': 'Chang Chih An', 'phone': '0981.234.567', 'team': 'Đội xe nhanh Q1'},
    {'name': 'Bùi Quang Trực', 'phone': '0978.889.991', 'team': 'Xe lạnh bảo quản'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeOrderStatus(Order order, OrderStatus newStatus) async {
    setState(() {
      order.status = newStatus;
    });
    await DataService.updateOrderStatus(order.id, newStatus);
    if (!mounted) return;
    SnackbarHelper.showSuccess(context, 'Đơn #${order.id} chuyển sang: ${_getStatusLabel(newStatus)}');
  }

  void _showAssignShipperDialog(Order order) {
    Map<String, String> selected = _availableShippers.first;
    bool useCustom = false;
    final customNameCtrl = TextEditingController();
    final customPhoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.two_wheeler, color: Colors.purple),
              const SizedBox(width: 8),
              Text('Gán Shipper cho đơn #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn nhân viên giao hàng thực tế:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ..._availableShippers.map((s) => RadioListTile<Map<String, String>>(
                      title: Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${s['phone']} • ${s['team']}', style: const TextStyle(fontSize: 12)),
                      value: s,
                      groupValue: useCustom ? null : selected,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          useCustom = false;
                          selected = val!;
                        });
                      },
                    )),
                RadioListTile<bool>(
                  title: const Text('Shipper ngoài / Tự nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  value: true,
                  groupValue: useCustom,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => useCustom = true),
                ),
                if (useCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Họ tên tài xế',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                String shipperName = selected['name']!;
                String shipperPhone = selected['phone']!;

                if (useCustom) {
                  if (customNameCtrl.text.trim().isEmpty || customPhoneCtrl.text.trim().isEmpty) {
                    SnackbarHelper.showError(context, 'Vui lòng nhập đủ họ tên và SĐT tài xế');
                    return;
                  }
                  shipperName = customNameCtrl.text.trim();
                  shipperPhone = customPhoneCtrl.text.trim();
                }

                Navigator.pop(ctx);
                await DataService.assignShipperToOrder(
                  orderId: order.id,
                  shipperName: shipperName,
                  shipperPhone: shipperPhone,
                );
                setState(() {
                  order.status = OrderStatus.delivering;
                  order.assignedShipperName = shipperName;
                  order.assignedShipperPhone = shipperPhone;
                });
                if (mounted) {
                  SnackbarHelper.showSuccess(context, 'Đã gán đơn cho shipper $shipperName ($shipperPhone)');
                }
              },
              child: const Text('Xác nhận gán'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelOrderDialog(Order order) {
    String selectedReason = 'Hết hàng trong kho';
    final customReasonCtrl = TextEditingController();
    final commonReasons = [
      'Hết hàng trong kho',
      'Khách yêu cầu hủy qua điện thoại',
      'Địa chỉ giao ngoài vùng phục vụ',
      'Không liên lạc được với khách hàng',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Text('Từ chối / Hủy đơn #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn lý do hủy / từ chối đơn hàng này:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                ...commonReasons.map((r) => RadioListTile<String>(
                      title: Text(r, style: const TextStyle(fontSize: 13)),
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => selectedReason = val!),
                    )),
                if (selectedReason == 'Lý do khác') ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: customReasonCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do chi tiết...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final reason = selectedReason == 'Lý do khác' && customReasonCtrl.text.trim().isNotEmpty
                    ? customReasonCtrl.text.trim()
                    : selectedReason;
                Navigator.pop(ctx);
                await DataService.cancelOrder(orderId: order.id, reason: reason);
                setState(() {
                  order.status = OrderStatus.cancelled;
                  order.cancellationReason = reason;
                });
                if (mounted) {
                  SnackbarHelper.showSuccess(context, 'Đã hủy đơn hàng #${order.id}');
                }
              },
              child: const Text('Xác nhận từ chối'),
            ),
          ],
        ),
      ),
    );
  }

  List<Order> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return DataService.orders.where((o) {
      final matchesQuery = query.isEmpty ||
          o.id.toLowerCase().contains(query) ||
          o.customerName.toLowerCase().contains(query) ||
          o.address.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedStatusFilter != null) {
        return o.status == _selectedStatusFilter;
      }
      return true;
    }).toList();
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Chờ xử lý';
      case OrderStatus.ready: return 'Đã gói xong';
      case OrderStatus.delivering: return 'Đang giao';
      case OrderStatus.completed: return 'Hoàn thành';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.ready: return Colors.blue;
      case OrderStatus.delivering: return Colors.purple;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;
    final totalCount = DataService.orders.length;
    final pendingCount = DataService.orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.ready).length;
    final completedCount = DataService.orders.where((o) => o.status == OrderStatus.completed).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Quản lý Đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            tooltip: 'Tải lại đơn hàng từ MongoDB',
            onPressed: () async {
              await DataService.refreshOrders();
              setState(() {});
              if (!context.mounted) return;
              SnackbarHelper.showSuccess(context, 'Đã cập nhật danh sách đơn hàng từ MongoDB');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Top Statistics Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _buildStatCard('Tổng đơn', '$totalCount', Colors.blue.shade700, Icons.receipt_long_rounded),
                const SizedBox(width: 8),
                _buildStatCard('Cần xử lý', '$pendingCount', Colors.orange.shade700, Icons.pending_actions_rounded),
                const SizedBox(width: 8),
                _buildStatCard('Hoàn thành', '$completedCount', Colors.green.shade700, Icons.check_circle_outline),
              ],
            ),
          ),

          // Search Bar & Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mã đơn, khách hàng, địa chỉ...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(null, 'Tất cả ($totalCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip(OrderStatus.pending, 'Chờ xử lý'),
                        const SizedBox(width: 8),
                        _buildFilterChip(OrderStatus.ready, 'Đã gói xong'),
                        const SizedBox(width: 8),
                        _buildFilterChip(OrderStatus.delivering, 'Đang giao'),
                        const SizedBox(width: 8),
                        _buildFilterChip(OrderStatus.completed, 'Hoàn thành'),
                        const SizedBox(width: 8),
                        _buildFilterChip(OrderStatus.cancelled, 'Đã hủy'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(OrderStatus? status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedStatusFilter = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Icon Box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đơn hàng #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Khách: ${order.customerName}',
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Địa chỉ: ${order.address}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng cộng: ${FormatHelper.formatPrice(order.totalAmount)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (order.assignedShipperName != null && order.assignedShipperName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.two_wheeler, size: 14, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                'Shipper: ${order.assignedShipperName} (${order.assignedShipperPhone ?? ""})',
                                style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (order.status == OrderStatus.cancelled && order.cancellationReason != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Lý do hủy: ${order.cancellationReason}',
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 20, thickness: 0.8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.receipt_long, size: 15),
                  label: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (order.status == OrderStatus.pending || order.status == OrderStatus.ready) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _showCancelOrderDialog(order),
                        child: const Text('Hủy / Từ chối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (order.status == OrderStatus.pending)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _changeOrderStatus(order, OrderStatus.ready),
                        child: const Text('Gói xong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    if (order.status == OrderStatus.ready)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _showAssignShipperDialog(order),
                        icon: const Icon(Icons.two_wheeler, size: 16),
                        label: const Text('Gán Shipper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    if (order.status == OrderStatus.delivering)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _changeOrderStatus(order, OrderStatus.completed),
                        child: const Text('Xác nhận đã giao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty || _selectedStatusFilter != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.receipt_long_outlined,
                size: 56,
                color: Colors.purple.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Không tìm thấy đơn hàng phù hợp' : 'Chưa có đơn hàng nào',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Hãy thử tìm kiếm với từ khóa khác.'
                  : 'Đơn hàng mới của khách sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
