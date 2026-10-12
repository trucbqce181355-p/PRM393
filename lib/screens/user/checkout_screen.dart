import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import 'user_home_screen.dart';
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

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    if (_selectedPayment == 'MOMO' || _selectedPayment == 'VNPAY') {
      // Mô phỏng Deep-link mở app Momo/VNPay
      _showPaymentGatewaySimulation();
      return;
    }

    // COD - Giả lập xử lý nhanh
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
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.pink),
            const SizedBox(height: 24),
            Text(
              'Đang chờ thanh toán qua \$_selectedPayment...',
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
                Navigator.pop(context); // Đóng Modal mô phỏng Momo
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

  void _completeOrder() async {
    // Generate order summary string from cart items
    final itemNames = Cart.items.map((i) => '${i.product.name} (x${i.quantity})').join(' + ');
    
    await StorageService.addOrder({
      'id': DateTime.now().millisecondsSinceEpoch.toString().substring(7),
      'status': 'Đang xử lý',
      'items': itemNames,
      'date': 'Vừa xong',
      'total': FormatHelper.formatPrice((Cart.totalAmount - _discountAmount > 0 ? Cart.totalAmount - _discountAmount : 0)),
    });

    if (!mounted) return;

    setState(() {
      Cart.items.clear();
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('${AuthService.userName ?? "Khách"} - 0987654321', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Padding(
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
                  children: Cart.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.product.name} (x${item.quantity})'),
                        Text(FormatHelper.formatPrice(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Section Voucher
              const Text('Khuyến mãi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            final code = _voucherController.text.toUpperCase();
                            
                            // Find voucher
                            Voucher? voucher;
                            try {
                              voucher = DataService.vouchers.firstWhere((v) => v.code == code && v.isActive);
                            } catch (e) {
                              voucher = null;
                            }
                            
                            if (voucher == null) {
                              SnackbarHelper.showError(context, 'Mã không hợp lệ hoặc đã hết hạn');
                              return;
                            }
                            if (Cart.totalAmount < voucher.minPurchase) {
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
                          Text('Đã áp dụng mã $_appliedVoucherCode (-${FormatHelper.formatPrice(_discountAmount)})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 100), // padding for bottom bar
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -5)),
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
                        FormatHelper.formatPrice(Cart.totalAmount),
                        style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough),
                      ),
                    Text(
                      FormatHelper.formatPrice(Cart.totalAmount - _discountAmount > 0 ? Cart.totalAmount - _discountAmount : 0),
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
