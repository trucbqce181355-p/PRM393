import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/snackbar_helper.dart';
import 'user_returns_screen.dart';
import 'user_support_chat_screen.dart';
import '../../utils/app_image_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  void _reloadOrder() {
    final fresh = DataService.orders.firstWhere(
      (o) => o.id == _order.id,
      orElse: () => _order,
    );
    setState(() => _order = fresh);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.blue;
      case OrderStatus.delivering:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Đang xử lý';
      case OrderStatus.ready:
        return 'Đã gói xong';
      case OrderStatus.delivering:
        return 'Đang giao hàng';
      case OrderStatus.completed:
        return 'Đã hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy đơn';
    }
  }

  void _showCancelOrderDialog() {
    final reasonController = TextEditingController();
    String selectedReason = 'Đổi ý không muốn mua nữa';
    final commonReasons = [
      'Đổi ý không muốn mua nữa',
      'Muốn thay đổi sản phẩm/địa chỉ',
      'Thời gian giao hàng quá lâu',
      'Tìm thấy chỗ bán rẻ hơn',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vui lòng chọn lý do bạn muốn hủy đơn hàng này:'),
                const SizedBox(height: 12),
                ...commonReasons.map((r) => RadioListTile<String>(
                      title: Text(r, style: const TextStyle(fontSize: 14)),
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => selectedReason = val!);
                      },
                    )),
                if (selectedReason == 'Lý do khác') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do chi tiết...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final reason = selectedReason == 'Lý do khác' && reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : selectedReason;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                await DataService.cancelOrder(orderId: _order.id, reason: reason);
                _reloadOrder();
                setState(() => _isLoading = false);
                if (mounted) {
                  SnackbarHelper.showSuccess(context, 'Đã hủy đơn hàng #${_order.id}');
                }
              },
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_order.status);
    final statusText = _getStatusText(_order.status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Đơn hàng #${_order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadOrder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withValues(alpha: 0.85), statusColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusText.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thời gian đặt: ${FormatHelper.formatDateTime(_order.createdAt)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (_order.status == OrderStatus.cancelled && _order.cancellationReason != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lý do hủy: ${_order.cancellationReason}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tracking Timeline (Stepper)
                  _buildTrackingTimeline(),

                  const SizedBox(height: 16),

                  // Shipper Information Card (if delivering or completed)
                  if (_order.assignedShipperName != null && _order.assignedShipperName!.isNotEmpty)
                    _buildShipperCard(),

                  // Receiver & Address Card
                  _buildDeliveryAddressCard(),

                  const SizedBox(height: 16),

                  // Order Items List
                  _buildOrderItemsCard(),

                  const SizedBox(height: 16),

                  // Payment & Financial Summary
                  _buildPaymentSummaryCard(),

                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTrackingTimeline() {
    int currentStep = 0;
    if (_order.status == OrderStatus.ready) currentStep = 1;
    if (_order.status == OrderStatus.delivering) currentStep = 2;
    if (_order.status == OrderStatus.completed) currentStep = 3;
    final isCancelled = _order.status == OrderStatus.cancelled;

    final steps = [
      {'title': 'Đặt hàng', 'subtitle': 'Đơn đã tiếp nhận', 'icon': Icons.receipt_long},
      {'title': 'Đóng gói', 'subtitle': 'Đã chọn trái cây', 'icon': Icons.inventory_2_outlined},
      {'title': 'Đang giao', 'subtitle': 'Shipper đang giao', 'icon': Icons.two_wheeler},
      {
        'title': isCancelled ? 'Đã hủy' : 'Hoàn thành',
        'subtitle': isCancelled ? 'Đơn bị hủy' : 'Đã nhận hàng',
        'icon': isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến trình vận chuyển',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                final isDone = !isCancelled && stepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isDone ? Colors.green : Colors.grey.shade300,
                  ),
                );
              }
              final stepIndex = index ~/ 2;
              final isDone = !isCancelled && stepIndex <= currentStep;
              final isCurrent = !isCancelled && stepIndex == currentStep;
              final step = steps[stepIndex];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCancelled && stepIndex == 3
                          ? Colors.red
                          : (isDone ? Colors.green : Colors.grey.shade200),
                      boxShadow: isCurrent
                          ? [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      size: 20,
                      color: (isDone || (isCancelled && stepIndex == 3)) ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? Colors.green : Colors.black87,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShipperCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple.shade700,
            radius: 24,
            child: const Icon(Icons.two_wheeler, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tài xế giao hàng',
                  style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold),
                ),
                Text(
                  _order.assignedShipperName ?? 'Shipper Fruitopia',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_order.assignedShipperPhone != null && _order.assignedShipperPhone!.isNotEmpty)
                  Text(
                    'SĐT: ${_order.assignedShipperPhone}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          if (_order.assignedShipperPhone != null && _order.assignedShipperPhone!.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                SnackbarHelper.showSuccess(context, 'Đang gọi tài xế: ${_order.assignedShipperPhone}');
              },
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Gọi'),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.green, size: 22),
              SizedBox(width: 8),
              Text(
                'Địa chỉ nhận hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            _order.customerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (_order.customerPhone != null && _order.customerPhone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _order.customerPhone!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _order.address,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          if (_order.deliveryNotes != null && _order.deliveryNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ghi chú: ${_order.deliveryNotes}',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    final hasDetailedItems = _order.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sản phẩm đã chọn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                hasDetailedItems ? '${_order.items.length} mặt hàng' : '',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20),
          if (hasDetailedItems)
            ..._order.items.map((item) {
              final name = item['productName'] ?? item['name'] ?? 'Trái cây tươi';
              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
              final unit = item['unit'] ?? 'kg';
              final img = item['imageUrl']?.toString() ?? '';
              final itemTotal = (item['total'] as num?)?.toDouble() ?? (price * qty);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AppImageHelper.buildImage(
                        imageUrl: img,
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorWidget: _buildFallbackImg(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${FormatHelper.formatPrice(price)} / $unit  ×  $qty',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      FormatHelper.formatPrice(itemTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
              );
            })
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _order.itemsSummary.isNotEmpty ? _order.itemsSummary : 'Trái cây tươi đóng hộp cao cấp',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackImg() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.green.shade50,
      child: const Icon(Icons.eco, color: Colors.green, size: 28),
    );
  }

  Widget _buildPaymentSummaryCard() {
    double subtotal = _order.totalAmount - _order.shippingFee + _order.discountAmount;
    if (subtotal < 0) subtotal = _order.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          _buildRow('Tiền hàng (Tạm tính)', FormatHelper.formatPrice(subtotal)),
          const SizedBox(height: 8),
          _buildRow(
            'Phí vận chuyển (${_order.shippingMethod == 'EXPRESS' ? 'Hỏa tốc' : 'Tiêu chuẩn'})',
            _order.shippingFee == 0 ? 'Miễn phí' : FormatHelper.formatPrice(_order.shippingFee),
          ),
          if (_order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildRow(
              'Giảm giá Voucher ${_order.voucherCode != null ? "(${_order.voucherCode})" : ""}',
              '-${FormatHelper.formatPrice(_order.discountAmount)}',
              color: Colors.red,
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                FormatHelper.formatPrice(_order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _order.paymentMethod.contains('MOMO')
                      ? Icons.account_balance_wallet
                      : Icons.payments_outlined,
                  size: 20,
                  color: _order.paymentMethod.contains('MOMO') ? Colors.pink : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Phương thức: ${_order.paymentMethod}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_order.status == OrderStatus.pending || _order.status == OrderStatus.ready) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showCancelOrderDialog,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy đơn hàng này', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_order.status == OrderStatus.completed) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserReturnsScreen(initialOrderId: _order.id),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Yêu cầu Đổi trả / Khiếu nại', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSupportChatScreen()),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Hỗ trợ & Khiếu nại trực tuyến', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
