import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

/// Màn hình UC Tạo Voucher (51_AddVoucher_Add)
/// Chức năng: Tạo voucher mới vào hệ thống
/// Không bao gồm: Sửa, Xóa, Danh sách, Bật/Tắt kích hoạt, Đơn tối thiểu, Giảm tối đa
class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({super.key});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _codeController.clear();
    _descController.clear();
    _discountController.clear();
    setState(() {});
  }

  Future<void> _createVoucher() async {
    final code = _codeController.text.trim().toUpperCase();
    final desc = _descController.text.trim();
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    // 1. Kiểm tra mã voucher không để trống
    if (code.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập mã voucher');
      return;
    }

    // 2. Kiểm tra trùng lặp mã voucher
    final isDuplicate = DataService.vouchers.any((v) => v.code.toUpperCase() == code);
    if (isDuplicate) {
      SnackbarHelper.showError(context, 'Mã voucher "$code" đã tồn tại!');
      return;
    }

    // 3. Kiểm tra số tiền giảm hợp lệ (> 0)
    if (discount <= 0) {
      SnackbarHelper.showError(context, 'Số tiền giảm phải lớn hơn 0');
      return;
    }

    setState(() => _isLoading = true);

    // 4. Tạo đối tượng Voucher mới (chỉ gồm code, description, discountAmount)
    final newVoucher = Voucher(
      code: code,
      description: desc.isNotEmpty ? desc : 'Giảm ${FormatHelper.formatPrice(discount)}',
      discountAmount: discount,
      minPurchase: 0.0,
      isActive: true,
    );

    // 5. Lưu voucher vào hệ thống (Hive Cache và MongoDB)
    await DataService.addVoucher(newVoucher);

    if (mounted) {
      setState(() => _isLoading = false);
      SnackbarHelper.showSuccess(context, 'Tạo voucher "$code" thành công!');
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDiscount = double.tryParse(_discountController.text.trim()) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Tạo Voucher mới',
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
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_card_rounded,
                        color: Colors.green.shade700,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tạo voucher khuyến mãi',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhập thông tin mã voucher và mức giảm giá để thêm vào hệ thống.',
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
                      'Thông tin voucher',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mã Voucher
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Mã voucher *',
                        hintText: 'VD: FRUIT50K, CHAOBANMOI',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                        helperText: 'Mã sẽ được tự động chuyển thành chữ in hoa',
                        helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                        labelText: 'Mô tả voucher',
                        hintText: 'VD: Giảm 50.000₫ cho khách hàng',
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
                            ? 'Mức giảm: ${FormatHelper.formatPrice(currentDiscount)}'
                            : 'Nhập số tiền giảm giá trực tiếp',
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

                    // Nút Tạo Voucher
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
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
                            : const Icon(Icons.add_task_rounded),
                        label: Text(
                          _isLoading ? 'Đang tạo...' : 'Tạo Voucher',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _isLoading ? null : _createVoucher,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Nút Làm mới form
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Làm mới form'),
                        onPressed: _resetForm,
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
