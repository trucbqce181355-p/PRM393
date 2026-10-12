import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../models/voucher.dart';
import '../../utils/format_helper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'COD';
  bool _isProcessing = false;
  String? _appliedVoucherCode;
  double _discountAmount = 0.0;
  final TextEditingController _voucherController = TextEditingController();

  final List<Map<String, dynamic>> _orderItems = const [
    {'name': 'Táo Fuji hữu cơ', 'quantity': 2, 'price': 60000.0},
    {'name': 'Nho Mẫu Đơn nhập khẩu', 'quantity': 1, 'price': 150000.0},
  ];

  double get _totalAmount {
    double total = 0.0;
    for (var item in _orderItems) {
      total += (item['price'] as double) * (item['quantity'] as int);
    }
    return total;
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    if (_selectedPayment == 'MOMO' || _selectedPayment == 'VNPAY') {
      _showPaymentGatewaySimulation();
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
    _completeOrder();
  }

  void _showPaymentGatewaySimulation() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              _selectedPayment == 'MOMO'
                  ? 'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png'
                  : 'https://vnpay.vn/s1/statics.vnpay.vn/2023/9/06ncktiwd6dc1694418196384.png',
              height: 60,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.pink),
            const SizedBox(height: 24),
            Text(
              'Đang chờ thanh toán qua $_selectedPayment...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng xác nhận trên ứng dụng của bạn.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _completeOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mô phỏng: Đã thanh toán thành công', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _completeOrder() {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Đặt hàng thành công!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn hàng của bạn đang được xử lý và sẽ sớm giao đến bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalTotal = (_totalAmount - _discountAmount > 0) ? (_totalAmount - _discountAmount) : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Info
              const Text('Thông tin giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Khách hàng - 0987654321', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.only(left: 32),
                      child: Text('Số 1, Đại Cồ Việt, Bách Khoa, Hai Bà Trưng, Hà Nội', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order Summary
              const Text('Tóm tắt đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: _orderItems.map((item) {
                    final itemTotal = (item['price'] as double) * (item['quantity'] as int);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item['name']} (x${item['quantity']})'),
                          Text(FormatHelper.formatPrice(itemTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Section Voucher
              const Text('Khuyến mãi & Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập mã giảm giá (VD: FREESHIP50)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final code = _voucherController.text.trim().toUpperCase();
                            
                            // Find voucher
                            Voucher? voucher;
                            try {
                              voucher = DataService.vouchers.firstWhere((v) => v.code == code && v.isActive);
                            } catch (_) {
                              voucher = null;
                            }
                            
                            if (voucher == null) {
                              SnackbarHelper.showError(context, 'Mã không hợp lệ hoặc đã hết hạn');
                              return;
                            }
                            if (_totalAmount < voucher.minPurchase) {
                              SnackbarHelper.showError(context, 'Đơn hàng chưa đạt mức tối thiểu ${FormatHelper.formatPrice(voucher.minPurchase)}');
                              return;
                            }
                            
                            setState(() {
                              _appliedVoucherCode = voucher!.code;
                              _discountAmount = voucher.discountAmount;
                            });
                            FocusScope.of(context).unfocus();
                            SnackbarHelper.showSuccess(context, 'Áp dụng mã thành công!');
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                    if (_appliedVoucherCode != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đã áp dụng mã $_appliedVoucherCode (-${FormatHelper.formatPrice(_discountAmount)})',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                _appliedVoucherCode = null;
                                _discountAmount = 0.0;
                                _voucherController.clear();
                              });
                            },
                          )
                        ],
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method
              const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Thanh toán tiền mặt (COD)'),
                      value: 'COD',
                      groupValue: _selectedPayment,
                      activeColor: Colors.green,
                      onChanged: (value) => setState(() => _selectedPayment = value!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.pink),
                          SizedBox(width: 8),
                          Text('Ví điện tử MoMo'),
                        ],
                      ),
                      value: 'MOMO',
                      groupValue: _selectedPayment,
                      activeColor: Colors.green,
                      onChanged: (value) => setState(() => _selectedPayment = value!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.payment, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('VNPay'),
                        ],
                      ),
                      value: 'VNPAY',
                      groupValue: _selectedPayment,
                      activeColor: Colors.green,
                      onChanged: (value) => setState(() => _selectedPayment = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    if (_discountAmount > 0)
                      Text(
                        FormatHelper.formatPrice(_totalAmount),
                        style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough),
                      ),
                    Text(
                      FormatHelper.formatPrice(finalTotal),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đặt hàng', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
