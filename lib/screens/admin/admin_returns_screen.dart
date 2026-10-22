import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/return_request.dart';
import '../../services/data_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/snackbar_helper.dart';

class AdminReturnsScreen extends StatefulWidget {
  const AdminReturnsScreen({super.key});

  @override
  State<AdminReturnsScreen> createState() => _AdminReturnsScreenState();
}

class _AdminReturnsScreenState extends State<AdminReturnsScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected', 'cancelled'

  List<ReturnRequest> get _filteredRequests {
    if (_selectedFilter == 'all') return DataService.returnRequests;
    return DataService.returnRequests.where((r) => r.status == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Đã chấp thuận';
      case 'rejected':
        return 'Đã từ chối';
      case 'cancelled':
        return 'Đã hủy';
      case 'pending':
      default:
        return 'Chờ xử lý';
    }
  }

  void _showProcessDialog(ReturnRequest req) {
    final replyCtrl = TextEditingController(text: req.adminReply ?? '');
    String decision = 'approved';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.rate_review_outlined, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xử lý yêu cầu #${req.id.substring(req.id.length > 6 ? req.id.length - 6 : 0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khách hàng: ${req.customerName} (${req.customerEmail})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Đơn hàng: #${req.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Lý do: ${req.reason}', style: const TextStyle(color: Colors.red)),
                if (req.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Mô tả của khách: ${req.description}', style: const TextStyle(fontSize: 13)),
                ],
                const Divider(height: 20),
                const Text('Quyết định xử lý:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Chấp thuận')),
                        selected: decision == 'approved',
                        selectedColor: Colors.green.shade100,
                        labelStyle: TextStyle(
                          color: decision == 'approved' ? Colors.green.shade900 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setDialogState(() => decision = 'approved'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Từ chối')),
                        selected: decision == 'rejected',
                        selectedColor: Colors.red.shade100,
                        labelStyle: TextStyle(
                          color: decision == 'rejected' ? Colors.red.shade900 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setDialogState(() => decision = 'rejected'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Ghi chú phản hồi cho khách hàng:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: replyCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập hướng xử lý (ví dụ: Shop đồng ý gửi lại giỏ quả mới hoặc hoàn tiền qua tài khoản)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
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
                backgroundColor: decision == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final replyText = replyCtrl.text.trim();
                if (replyText.isEmpty) {
                  SnackbarHelper.showError(context, 'Vui lòng nhập nội dung phản hồi cho khách');
                  return;
                }
                Navigator.pop(ctx);
                await DataService.replyReturnRequest(
                  requestId: req.id,
                  status: decision,
                  reply: replyText,
                );
                setState(() {});
                if (mounted) {
                  SnackbarHelper.showSuccess(
                    context,
                    'Đã ${decision == 'approved' ? 'chấp thuận' : 'từ chối'} và gửi thông báo đến khách hàng!',
                  );
                }
              },
              child: const Text('Lưu & Phản hồi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredRequests;
    final pendingCount = DataService.returnRequests.where((r) => r.status == 'pending').length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý Đổi trả & Khiếu nại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả (${DataService.returnRequests.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Chờ xử lý ($pendingCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('approved', 'Đã duyệt'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Đã từ chối'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Đã hủy'),
              ],
            ),
          ),

          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'pending'
                              ? 'Không có yêu cầu nào đang chờ xử lý 🎉'
                              : 'Không có yêu cầu nào trong mục này',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final r = list[index];
                      final statusColor = _getStatusColor(r.status);
                      final statusText = _getStatusText(r.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt_long, size: 20, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Đơn hàng #${r.orderId}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Khách hàng: ${r.customerName} (${r.customerEmail})',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian: ${FormatHelper.formatDateTime(r.createdAt)}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                              const Divider(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Lý do: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Expanded(
                                    child: Text(r.reason, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ),
                                ],
                              ),
                              if (r.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Mô tả chi tiết: ${r.description}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                ),
                              ],
                              if (r.imageUrl != null && r.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: r.imageUrl!.startsWith('http')
                                      ? Image.network(
                                          r.imageUrl!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(r.imageUrl!),
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Text('Lỗi ảnh'),
                                        ),
                                ),
                              ],
                              if (r.adminReply != null && r.adminReply!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.reply, size: 18, color: Colors.blue.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Phản hồi đã gửi cho khách:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(r.adminReply!, style: TextStyle(fontSize: 13, color: Colors.blue.shade900)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: r.status == 'pending' ? Colors.green : Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _showProcessDialog(r),
                                  icon: const Icon(Icons.edit_note, size: 18),
                                  label: Text(r.status == 'pending' ? 'Xử lý yêu cầu này' : 'Cập nhật lại phản hồi'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}
