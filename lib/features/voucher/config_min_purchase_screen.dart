import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';

/// Màn hình UC Thiết lập giá trị đơn hàng tối thiểu (55_Thiết lập giá trị đơn hàng tối thiểu của Voucher)
/// Chức năng: Thiết lập số tiền đơn hàng tối thiểu (minPurchase) để voucher có thể được áp dụng
/// Không bao gồm: Tạo mới, Xóa, Cấu hình loại giảm giá %, Giảm tối đa, Kích hoạt / Vô hiệu hóa, Áp dụng tại thanh toán
class ConfigMinPurchaseScreen extends StatefulWidget {
  final Voucher? voucher;

  const ConfigMinPurchaseScreen({super.key, this.voucher});

  @override
  State<ConfigMinPurchaseScreen> createState() => _ConfigMinPurchaseScreenState();
}

class _ConfigMinPurchaseScreenState extends State<ConfigMinPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  Voucher? _selectedVoucher;
  final TextEditingController _minPurchaseController = TextEditingController();
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
    _minPurchaseController.text = voucher.minPurchase.toStringAsFixed(0);
    setState(() {});
  }

  @override
  void dispose() {
    _minPurchaseController.dispose();
    super.dispose();
  }

  Future<void> _saveMinPurchase() async {
    if (_selectedVoucher == null) {
      SnackbarHelper.showError(context, 'Chưa chọn voucher cần thiết lập');
      return;
    }

    final minPurchase = double.tryParse(_minPurchaseController.text.trim()) ?? 0.0;

    if (minPurchase < 0) {
      SnackbarHelper.showError(context, 'Giá trị đơn tối thiểu không được âm');
      return;
    }

    setState(() => _isLoading = true);

    // Cập nhật giá trị đơn hàng tối thiểu (minPurchase) cho voucher
    final updatedVoucher = _selectedVoucher!.copyWith(
      minPurchase: minPurchase,
    );

    // Lưu vào DataService (đồng bộ Hive Cache và MongoDB)
    await DataService.updateVoucher(_selectedVoucher!.code, updatedVoucher);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedVoucher = updatedVoucher;
      });
      SnackbarHelper.showSuccess(
        context,
        minPurchase > 0
            ? 'Đã thiết lập đơn tối thiểu ${FormatHelper.formatPrice(minPurchase)} cho mã "${updatedVoucher.code}"'
            : 'Đã bỏ giới hạn đơn tối thiểu cho mã "${updatedVoucher.code}"',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMinPurchase = double.tryParse(_minPurchaseController.text.trim()) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text(
          'Thiết lập đơn tối thiểu',
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.blue.shade700,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đơn hàng tối thiểu (minPurchase)',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cấu hình mức tiền tối thiểu để đơn hàng được phép áp dụng voucher.',
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
                    // Chọn voucher nếu mở trực tiếp không truyền param
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
                            child: Text('${v.code} (Đơn từ: ${FormatHelper.formatPrice(v.minPurchase)})'),
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
                      // Box tóm tắt thông tin voucher hiện tại
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_outlined, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Mã: ${_selectedVoucher!.code}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                            ),
                            const Spacer(),
                            Text(
                              'Mức giảm: ${FormatHelper.formatPrice(_selectedVoucher!.discountAmount)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      'Thiết lập giá trị tối thiểu:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ô nhập đơn tối thiểu
                    TextField(
                      controller: _minPurchaseController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Đơn hàng tối thiểu (₫) *',
                        hintText: 'VD: 100000 (nhập 0 nếu không yêu cầu)',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        helperText: currentMinPurchase > 0
                            ? 'Áp dụng cho đơn từ: ${FormatHelper.formatPrice(currentMinPurchase)}'
                            : 'Không giới hạn đơn tối thiểu (áp dụng cho mọi đơn)',
                        helperStyle: TextStyle(
                          color: currentMinPurchase > 0 ? Colors.blue.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Các nút chọn nhanh mốc tiền phổ biến
                    const Text(
                      'Chọn nhanh mốc giá trị:',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('0₫ (Không giới hạn)'),
                          onPressed: () {
                            _minPurchaseController.text = '0';
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('50.000₫'),
                          onPressed: () {
                            _minPurchaseController.text = '50000';
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('100.000₫'),
                          onPressed: () {
                            _minPurchaseController.text = '100000';
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('200.000₫'),
                          onPressed: () {
                            _minPurchaseController.text = '200000';
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Nút Lưu giá trị đơn tối thiểu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
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
                          _isLoading ? 'Đang lưu...' : 'Lưu giá trị đơn tối thiểu',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _saveMinPurchase,
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
