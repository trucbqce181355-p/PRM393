import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

/// Màn hình UC Chỉnh sửa Voucher (52_Chỉnh sửa Voucher_Edit)
/// Chức năng: Cập nhật thông tin mô tả và số tiền giảm giá của voucher
/// Không bao gồm: Xóa, Cấu hình loại giảm giá %, Thiết lập đơn tối thiểu,
/// Giảm tối đa, Kích hoạt / Vô hiệu hóa, Áp dụng tại thanh toán
class EditVoucherScreen extends StatefulWidget {
  final Voucher? voucher;

  const EditVoucherScreen({super.key, this.voucher});

  @override
  State<EditVoucherScreen> createState() => _EditVoucherScreenState();
}

class _EditVoucherScreenState extends State<EditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  Voucher? _selectedVoucher;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      _loadVoucherData(widget.voucher!);
    } else if (DataService.vouchers.isNotEmpty) {
      _loadVoucherData(DataService.vouchers.first);
    }
  }

  void _loadVoucherData(Voucher voucher) {
    _selectedVoucher = voucher;
    _codeController.text = voucher.code;
    _descController.text = voucher.description;
    _discountController.text = voucher.discountAmount.toStringAsFixed(0);
    setState(() {});
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_selectedVoucher == null) {
      SnackbarHelper.showError(context, 'Chưa chọn voucher cần chỉnh sửa');
      return;
    }

    final desc = _descController.text.trim();
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    // 1. Kiểm tra số tiền giảm hợp lệ
    if (discount <= 0) {
      SnackbarHelper.showError(context, 'Số tiền giảm phải lớn hơn 0');
      return;
    }

    setState(() => _isLoading = true);

    // 2. Tạo đối tượng Voucher đã cập nhật (giữ nguyên code gốc và trạng thái hiện tại)
    final updatedVoucher = _selectedVoucher!.copyWith(
      description: desc.isNotEmpty ? desc : 'Giảm ${FormatHelper.formatPrice(discount)}',
      discountAmount: discount,
    );

    // 3. Gọi hàm cập nhật trong DataService (lưu vào Hive Cache và MongoDB)
    await DataService.updateVoucher(_selectedVoucher!.code, updatedVoucher);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedVoucher = updatedVoucher;
      });
      SnackbarHelper.showSuccess(context, 'Cập nhật voucher "${updatedVoucher.code}" thành công!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDiscount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa Voucher',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
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
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: Colors.orange.shade700,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cập nhật Voucher',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chỉnh sửa mô tả và mức giảm giá của voucher đã tạo.',
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

              // Form Card
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
                    const Text(
                      'Thông tin chỉnh sửa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chọn voucher cần sửa nếu mở trực tiếp không truyền param
                    if (widget.voucher == null && DataService.vouchers.isNotEmpty) ...[
                      DropdownButtonFormField<Voucher>(
                        initialValue: _selectedVoucher,
                        decoration: InputDecoration(
                          labelText: 'Chọn voucher cần chỉnh sửa',
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
                            _loadVoucherData(selected);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Mã Voucher (Chỉ đọc để tránh sai lệch mã định danh)
                    TextField(
                      controller: _codeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Mã voucher',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        helperText: 'Mã voucher không thay đổi',
                        helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mô tả
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả voucher *',
                        hintText: 'VD: Giảm 50.000₫ cho đơn hàng trái cây',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Số tiền giảm
                    TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Số tiền giảm (₫) *',
                        hintText: 'VD: 50000',
                        prefixIcon: const Icon(Icons.discount_outlined),
                        helperText: currentDiscount > 0
                            ? 'Mức giảm mới: ${FormatHelper.formatPrice(currentDiscount)}'
                            : 'Nhập số tiền giảm giá mới',
                        helperStyle: TextStyle(
                          color: currentDiscount > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: currentDiscount > 0 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nút Lưu thay đổi
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isLoading ? 'Đang lưu...' : 'Lưu thay đổi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _isLoading ? null : _saveChanges,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
