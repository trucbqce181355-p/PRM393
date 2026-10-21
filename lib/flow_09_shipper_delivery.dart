import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/delivery_confirmation_service.dart';
import 'order_service.dart';
import 'services/shipper_order_workflow.dart';
import 'snackbar_helper.dart';

class ShipperOrdersScreen extends StatefulWidget {
  const ShipperOrdersScreen({super.key});

  @override
  State<ShipperOrdersScreen> createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  final Set<String> _busyOrderIds = {};

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final orders = await OrderService.getOrders();
    return orders
        .where(
          (order) =>
              order['status'] == 'Đang xử lý' || order['status'] == 'Đang giao',
        )
        .toList();
  }

  void _refreshOrders() {
    setState(() => _ordersFuture = _loadOrders());
  }

  Future<void> _updateOrder(
    String orderId,
    Future<bool> Function() update,
  ) async {
    setState(() => _busyOrderIds.add(orderId));
    try {
      final updated = await update();
      if (!updated) {
        throw StateError('Không tìm thấy đơn hàng #$orderId.');
      }
      if (!mounted) return;
      _refreshOrders();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Không thể cập nhật đơn hàng: $error');
    } finally {
      _busyOrderIds.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openDirections(Map<String, dynamic> order) async {
    final address = (order['address'] as String?)?.trim();
    if (address == null || address.isEmpty) {
      SnackbarHelper.showError(context, 'Đơn hàng chưa có địa chỉ giao.');
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': address,
      'travelmode': 'driving',
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        SnackbarHelper.showError(context, 'Không mở được ứng dụng bản đồ.');
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Không thể mở bản đồ: $error');
      }
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final orderId = order['id'].toString();
    await _updateOrder(
      orderId,
      () => ShipperOrderWorkflow.markAsDelivering(orderId),
    );
  }

  Future<void> _checkInAndComplete(Map<String, dynamic> order) async {
    final orderId = order['id'].toString();
    setState(() => _busyOrderIds.add(orderId));
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo == null) return;

      final updated = await DeliveryConfirmationService.confirmDelivered(
        orderId: orderId,
        photo: photo,
      );
      if (!updated) {
        throw StateError('Không tìm thấy đơn hàng #$orderId.');
      }
      if (mounted) {
        _refreshOrders();
        SnackbarHelper.showSuccess(context, 'Đã chụp ảnh và đóng đơn hàng.');
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Không thể check-in đơn hàng: $error',
        );
      }
    } finally {
      _busyOrderIds.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Đơn hàng cần giao',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refreshOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildLoadError(snapshot.error);
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Hiện chưa có đơn hàng cần giao',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderCard(orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Không tải được đơn hàng từ MongoDB.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _refreshOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final isDelivering = order['status'] == 'Đang giao';
    final isBusy = _busyOrderIds.contains(orderId);
    final photoPath = order['deliveryPhotoPath'] as String?;

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
                Text(
                  'Đơn hàng #$orderId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(order['status'] as String? ?? 'Đang xử lý'),
                  backgroundColor: isDelivering
                      ? Colors.blue[50]
                      : Colors.orange[50],
                  labelStyle: TextStyle(
                    color: isDelivering ? Colors.blue[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              order['customerName'] as String? ?? 'Khách hàng',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              order['address'] as String? ?? 'Chưa có địa chỉ giao hàng',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              'Sản phẩm: ${order['items'] ?? 'Không có thông tin'}',
              style: const TextStyle(color: Colors.black54),
            ),
            if (photoPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(photoPath),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Text(
                    'Ảnh check-in đã lưu nhưng không thể hiển thị.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isDelivering) ...[
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => _openDirections(order),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Mở bản đồ chỉ đường'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => _checkInAndComplete(order),
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh check-in & hoàn tất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: isBusy ? null : () => _acceptOrder(order),
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.local_shipping_outlined),
                label: const Text('Nhận đơn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
