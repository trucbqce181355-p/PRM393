import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/return_request.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/snackbar_helper.dart';

class UserReturnsScreen extends StatefulWidget {
  final String? initialOrderId;

  const UserReturnsScreen({super.key, this.initialOrderId});

  @override
  State<UserReturnsScreen> createState() => _UserReturnsScreenState();
}

class _UserReturnsScreenState extends State<UserReturnsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  // Create form state
  String? _selectedOrder;
  String? _selectedReason;
  final TextEditingController _descController = TextEditingController();
  String? _pickedImagePath;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Sản phẩm bị dập nát/hư hỏng',
    'Giao sai sản phẩm / thiếu số lượng',
    'Sản phẩm không tươi / kém chất lượng',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOrder = widget.initialOrderId;
    // Default to tab 1 (Tạo mới) if opened with orderId, otherwise tab 0 (Danh sách)
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialOrderId != null ? 1 : 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<ReturnRequest> get _userRequests {
    final email = (AuthService.userEmail ?? '').trim().toLowerCase();
    return DataService.returnRequests
        .where((r) => r.customerEmail.trim().toLowerCase() == email)
        .toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _pickedImagePath = file.path);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Không thể chọn ảnh: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn ảnh minh chứng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Chọn từ thư viện ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitReturnRequest() async {
    if (_selectedOrder == null || _selectedOrder!.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng chọn đơn hàng cần đổi/trả');
      return;
    }
    if (_selectedReason == null || _selectedReason!.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng chọn lý do khiếu nại');
      return;
    }

    setState(() => _isSubmitting = true);

    final newReq = ReturnRequest(
      id: 'rr_${DateTime.now().millisecondsSinceEpoch}',
      orderId: _selectedOrder!,
      customerEmail: AuthService.userEmail ?? 'khach@fruitopia.com',
      customerName: AuthService.userName ?? 'Khách hàng',
      reason: _selectedReason!,
      description: _descController.text.trim(),
      imageUrl: _pickedImagePath,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await DataService.addReturnRequest(newReq);

    setState(() {
      _isSubmitting = false;
      _descController.clear();
      _pickedImagePath = null;
      _selectedReason = null;
    });

    if (!mounted) return;
    SnackbarHelper.showSuccess(context, 'Đã gửi yêu cầu đổi/trả thành công!');
    _tabController.animateTo(0); // Switch to list tab
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

  void _showRequestDetails(ReturnRequest req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yêu cầu #${req.id.substring(req.id.length > 8 ? req.id.length - 8 : 0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(req.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(req.status),
                        style: TextStyle(
                          color: _getStatusColor(req.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Mã đơn hàng:', '#${req.orderId}'),
                const SizedBox(height: 8),
                _buildDetailRow('Ngày gửi:', FormatHelper.formatDateTime(req.createdAt)),
                const SizedBox(height: 8),
                _buildDetailRow('Lý do:', req.reason),
                if (req.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Chi tiết mô tả:', req.description),
                ],
                if (req.imageUrl != null && req.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Ảnh minh chứng đính kèm:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: req.imageUrl!.startsWith('http')
                        ? Image.network(
                            req.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(req.imageUrl!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Text('Không thể tải ảnh minh chứng'),
                          ),
                  ),
                ],
                const SizedBox(height: 20),
                // Admin Reply Box
                if (req.adminReply != null && req.adminReply!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent, color: Colors.blue.shade800, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Phản hồi từ Fruitopia Shop:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          req.adminReply!,
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Actions: Sửa & Hủy (chỉ khả dụng khi status == 'pending')
                if (req.status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            _confirmCancelRequest(req);
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Hủy yêu cầu này'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _editRequestDialog(req);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Sửa yêu cầu'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ],
    );
  }

  void _confirmCancelRequest(ReturnRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu khiếu nại này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await DataService.cancelReturnRequest(req.id);
              setState(() {});
              if (mounted) {
                SnackbarHelper.showSuccess(context, 'Đã hủy yêu cầu khiếu nại thành công');
              }
            },
            child: const Text('Đồng ý hủy'),
          ),
        ],
      ),
    );
  }

  void _editRequestDialog(ReturnRequest req) {
    String editReason = req.reason;
    final editDescCtrl = TextEditingController(text: req.description);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chỉnh sửa yêu cầu', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lý do:'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: editReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => setDialogState(() => editReason = val!),
                ),
                const SizedBox(height: 14),
                const Text('Mô tả chi tiết:'),
                const SizedBox(height: 6),
                TextField(
                  controller: editDescCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                final updated = req.copyWith(
                  reason: editReason,
                  description: editDescCtrl.text.trim(),
                  updatedAt: DateTime.now(),
                );
                Navigator.pop(ctx);
                await DataService.updateReturnRequest(updated);
                setState(() {});
                if (mounted) {
                  SnackbarHelper.showSuccess(context, 'Đã cập nhật yêu cầu khiếu nại!');
                }
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Đổi trả & Khiếu nại', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Yêu cầu của tôi'),
                  if (_userRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_userRequests.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Tạo yêu cầu mới'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Danh sách yêu cầu của tôi
          _buildMyRequestsTab(),

          // Tab 2: Tạo yêu cầu mới
          _buildCreateRequestTab(),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    final requests = _userRequests;

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_return_outlined, size: 70, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa có yêu cầu đổi trả nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nếu đơn hàng gặp vấn đề hư hỏng hoặc sai mẫu, hãy gửi yêu cầu để Fruitopia hỗ trợ bạn ngay!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.add),
                label: const Text('Tạo yêu cầu ngay'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final r = requests[index];
        final statusColor = _getStatusColor(r.status);
        final statusText = _getStatusText(r.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showRequestDetails(r),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đơn hàng #${r.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.report_problem_outlined, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.reason,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.description,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        FormatHelper.formatDateTime(r.createdAt),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const Row(
                        children: [
                          Text('Chi tiết', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right, size: 18, color: Colors.green),
                        ],
                      ),
                    ],
                  ),
                  if (r.adminReply != null && r.adminReply!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: Colors.blue.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Shop đã phản hồi: ${r.adminReply}',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateRequestTab() {
    final userOrders = DataService.getOrdersForCustomer(AuthService.userEmail);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn đơn hàng cần khiếu nại / đổi trả',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedOrder,
                hint: Text(
                  userOrders.isEmpty ? 'Bạn chưa có đơn hàng nào' : 'Chọn mã đơn hàng',
                  style: TextStyle(color: userOrders.isEmpty ? Colors.grey : Colors.black87),
                ),
                items: userOrders
                    .map((o) => DropdownMenuItem(
                          value: o.id,
                          child: Text(
                            '#${o.id} - ${FormatHelper.formatPrice(o.totalAmount)} (${o.itemsSummary.isNotEmpty ? o.itemsSummary : "Trái cây"})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedOrder = val),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Lý do khiếu nại',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedReason,
                hint: const Text('Chọn lý do phù hợp'),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Mô tả chi tiết tình trạng',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Mô tả rõ vấn đề của sản phẩm để cửa hàng giải quyết nhanh chóng...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Hình ảnh minh chứng sản phẩm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_pickedImagePath != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_pickedImagePath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _pickedImagePath = null),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.green.shade600),
                    const SizedBox(height: 6),
                    Text(
                      'Bấm để tải ảnh chụp quả bị lỗi/hỏng',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text('Chụp ảnh camera hoặc chọn từ thư viện', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _submitReturnRequest,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Gửi yêu cầu đổi trả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
