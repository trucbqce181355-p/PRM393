import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

enum DiscountType {
  fixedAmount, // Giảm theo số tiền cố định (₫)
  percentage,  // Giảm theo phần trăm (%)
}

/// Màn hình UC Cấu hình loại giảm giá của voucher (54_Cấu hình loại giảm giá của Voucher)
/// Chức năng: Thiết lập loại giảm giá (tiền mặt cố định ₫ hoặc theo tỷ lệ %) cho voucher
/// Không bao gồm: Tạo mới, Xóa, Thiết lập đơn tối thiểu, Giảm tối đa, Kích hoạt / Vô hiệu hóa, Áp dụng tại thanh toán
class ConfigDiscountTypeScreen extends StatefulWidget {
  final Voucher? voucher;

  const ConfigDiscountTypeScreen({super.key, this.voucher});

  @override
  State<ConfigDiscountTypeScreen> createState() => _ConfigDiscountTypeScreenState();
}

class _ConfigDiscountTypeScreenState extends State<ConfigDiscountTypeScreen> {
  final _formKey = GlobalKey<FormState>();
  Voucher? _selectedVoucher;
  DiscountType _selectedType = DiscountType.fixedAmount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _percentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      _loadVoucher(widget.voucher!);
    } else if (DataService.vouchers.isNotEmpty) {
      _loadVoucher(DataService.vouchers.first);
    }
  }

  void _loadVoucher(Voucher voucher) {
    _selectedVoucher = voucher;
    // Kiểm tra nếu discountAmount <= 100 coi như phần trăm hoặc mặc định tiền mặt
    if (voucher.discountAmount > 0 && voucher.discountAmount <= 100 && voucher.description.contains('%')) {
      _selectedType = DiscountType.percentage;
      _percentController.text = voucher.discountAmount.toStringAsFixed(0);
      _amountController.text = '20000';
    } else {
      _selectedType = DiscountType.fixedAmount;
      _amountController.text = voucher.discountAmount > 0 ? voucher.discountAmount.toStringAsFixed(0) : '20000';
      _percentController.text = '10';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _saveDiscountTypeConfig() async {
    if (_selectedVoucher == null) {
      SnackbarHelper.showError(context, 'Chưa chọn voucher cần cấu hình');
      return;
    }

    double discountValue = 0.0;
    String newDescription = '';

    if (_selectedType == DiscountType.fixedAmount) {
      discountValue = double.tryParse(_amountController.text.trim()) ?? 0.0;
      if (discountValue <= 0) {
        SnackbarHelper.showError(context, 'Số tiền giảm phải lớn hơn 0₫');
        return;
      }
      newDescription = 'Giảm trực tiếp ${FormatHelper.formatPrice(discountValue)} cho đơn hàng';
    } else {
      discountValue = double.tryParse(_percentController.text.trim()) ?? 0.0;
      if (discountValue <= 0 || discountValue > 100) {
        SnackbarHelper.showError(context, 'Phần trăm giảm giá phải từ 1% đến 100%');
        return;
      }
      newDescription = 'Giảm ${discountValue.toStringAsFixed(0)}% trên tổng giá trị đơn hàng';
    }

    setState(() => _isLoading = true);

    // Cập nhật cấu hình loại giảm giá vào voucher
    final updatedVoucher = _selectedVoucher!.copyWith(
      discountAmount: discountValue,
      description: newDescription,
    );

    await DataService.updateVoucher(_selectedVoucher!.code, updatedVoucher);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedVoucher = updatedVoucher;
      });
      SnackbarHelper.showSuccess(
        context,
        'Cấu hình loại giảm giá voucher "${updatedVoucher.code}" thành công!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final currentPercent = double.tryParse(_percentController.text.trim()) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Cấu hình loại giảm giá',
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
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.deepPurple.shade700,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cấu hình loại giảm giá',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thiết lập loại giảm theo số tiền cố định (₫) hoặc theo phần trăm (%).',
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
                    // Chọn voucher nếu mở trực tiếp
                    if (widget.voucher == null && DataService.vouchers.isNotEmpty) ...[
                      const Text(
                        'Chọn voucher cấu hình:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            child: Text('${v.code} - ${v.description}'),
                          );
                        }).toList(),
                        onChanged: (selected) {
                          if (selected != null) {
                            _loadVoucher(selected);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_selectedVoucher != null) ...[
                      // Thông tin voucher đang chọn
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, color: Colors.deepPurple, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Mã voucher: ',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                            Text(
                              _selectedVoucher!.code,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      'Chọn loại giảm giá:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lựa chọn 1: Số tiền cố định
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedType == DiscountType.fixedAmount ? Colors.deepPurple.shade50.withValues(alpha: 0.5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == DiscountType.fixedAmount ? Colors.deepPurple : Colors.grey.shade300,
                          width: _selectedType == DiscountType.fixedAmount ? 1.5 : 1,
                        ),
                      ),
                      child: RadioListTile<DiscountType>(
                        value: DiscountType.fixedAmount,
                        groupValue: _selectedType,
                        activeColor: Colors.deepPurple,
                        title: const Text('Giảm theo số tiền cố định (₫)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Trừ một khoản tiền cố định trực tiếp vào đơn hàng', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Lựa chọn 2: Phần trăm
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedType == DiscountType.percentage ? Colors.deepPurple.shade50.withValues(alpha: 0.5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedType == DiscountType.percentage ? Colors.deepPurple : Colors.grey.shade300,
                          width: _selectedType == DiscountType.percentage ? 1.5 : 1,
                        ),
                      ),
                      child: RadioListTile<DiscountType>(
                        value: DiscountType.percentage,
                        groupValue: _selectedType,
                        activeColor: Colors.deepPurple,
                        title: const Text('Giảm theo phần trăm (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Chiết khấu theo tỷ lệ % trên tổng tiền hàng (tối đa 100%)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Trường nhập giá trị theo loại đã chọn
                    if (_selectedType == DiscountType.fixedAmount) ...[
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Số tiền giảm (₫) *',
                          hintText: 'VD: 30000',
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          helperText: currentAmount > 0
                              ? 'Mức giảm cố định: ${FormatHelper.formatPrice(currentAmount)}'
                              : 'Nhập số tiền giảm bằng chữ số',
                          helperStyle: TextStyle(
                            color: currentAmount > 0 ? Colors.deepPurple : Colors.grey.shade600,
                            fontWeight: currentAmount > 0 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _percentController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Tỷ lệ phần trăm giảm (%) *',
                          hintText: 'VD: 15 (từ 1% đến 100%)',
                          prefixIcon: const Icon(Icons.percent_rounded),
                          helperText: currentPercent > 0 && currentPercent <= 100
                              ? 'Chiết khấu: Giảm ${currentPercent.toStringAsFixed(0)}% trên tổng đơn'
                              : 'Nhập phần trăm hợp lệ từ 1 - 100',
                          helperStyle: TextStyle(
                            color: currentPercent > 0 && currentPercent <= 100 ? Colors.deepPurple : Colors.grey.shade600,
                            fontWeight: currentPercent > 0 && currentPercent <= 100 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Nút Lưu cấu hình
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
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
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _isLoading ? 'Đang lưu cấu hình...' : 'Lưu cấu hình loại giảm giá',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _saveDiscountTypeConfig,
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
