import 'package:flutter/material.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

/// Màn hình UC Xóa Voucher (53_Xóa Voucher_Delete)
/// Chức năng: Xác nhận và xóa voucher khỏi hệ thống (Hive Cache và MongoDB)
/// Không bao gồm: Tạo, Chỉnh sửa, Cấu hình loại giảm giá %, Thiết lập đơn tối thiểu,
/// Giảm tối đa, Kích hoạt / Vô hiệu hóa, Áp dụng tại thanh toán
class DeleteVoucherScreen extends StatefulWidget {
  final Voucher? voucher;

  const DeleteVoucherScreen({super.key, this.voucher});

  @override
  State<DeleteVoucherScreen> createState() => _DeleteVoucherScreenState();
}

class _DeleteVoucherScreenState extends State<DeleteVoucherScreen> {
  Voucher? _selectedVoucher;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      _selectedVoucher = widget.voucher;
    } else if (DataService.vouchers.isNotEmpty) {
      _selectedVoucher = DataService.vouchers.first;
    }
  }

  Future<void> _confirmDelete() async {
    if (_selectedVoucher == null) {
      SnackbarHelper.showError(context, 'Chưa chọn voucher cần xóa');
      return;
    }

    final voucherCode = _selectedVoucher!.code;

    setState(() => _isDeleting = true);

    // 1. Gọi hàm xóa voucher trong DataService (xóa khỏi memory, Hive cache và MongoDB)
    await DataService.deleteVoucher(voucherCode);

    if (mounted) {
      setState(() {
        _isDeleting = false;
        _selectedVoucher = DataService.vouchers.isNotEmpty ? DataService.vouchers.first : null;
      });

      SnackbarHelper.showSuccess(context, 'Đã xóa voucher "$voucherCode" thành công!');

      // Nếu được mở dạng push từ màn hình khác, tự động quay lại
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Xóa Voucher',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xóa mã Voucher',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gỡ bỏ vĩnh viễn voucher khỏi cơ sở dữ liệu hệ thống.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chọn voucher cần xóa nếu mở trực tiếp không truyền param
                  if (widget.voucher == null && DataService.vouchers.isNotEmpty) ...[
                    const Text(
                      'Chọn voucher cần xóa:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Voucher>(
                      initialValue: _selectedVoucher,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      items: DataService.vouchers.map((v) {
                        return DropdownMenuItem<Voucher>(
                          value: v,
                          child: Text('${v.code} (${FormatHelper.formatPrice(v.discountAmount)})'),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          setState(() => _selectedVoucher = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_selectedVoucher == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Không có voucher nào trong hệ thống.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ),
                    )
                  else ...[
                    // Chi tiết voucher sắp xóa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedVoucher!.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.red,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Giảm: ${FormatHelper.formatPrice(_selectedVoucher!.discountAmount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedVoucher!.description,
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cảnh báo không thể hoàn tác
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cảnh báo: Hành động xóa không thể hoàn tác. Mã voucher này sẽ bị xóa vĩnh viễn khỏi cơ sở dữ liệu.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nút Xác nhận xóa
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.delete_forever_rounded),
                        label: Text(
                          _isDeleting ? 'Đang xóa...' : 'Xác nhận xóa Voucher',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _isDeleting ? null : _confirmDelete,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Nút Hủy
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Hủy bỏ'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
