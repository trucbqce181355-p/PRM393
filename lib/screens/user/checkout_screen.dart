import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import 'user_home_screen.dart';
import 'user_addresses_screen.dart';
import '../auth/login_screen.dart';
import '../../models/voucher.dart';
import '../../utils/format_helper.dart';

class CheckoutScreen extends StatefulWidget {
  final String? initialVoucherCode;
  const CheckoutScreen({super.key, this.initialVoucherCode});

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
  void initState() {
    super.initState();
    if (!AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !AuthService.isLoggedIn) {
          SnackbarHelper.showError(context, 'Vui lòng đăng nhập để tiến hành mua hàng!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen(redirectToCheckout: true)),
          );
        }
      });
    } else if (widget.initialVoucherCode != null && widget.initialVoucherCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyVoucherCode(widget.initialVoucherCode!, showMessage: false);
        }
      });
    }
  }

  void _applyVoucherCode(String inputCode, {bool showMessage = true}) {
    final code = inputCode.trim().toUpperCase();
    if (code.isEmpty) {
      if (showMessage) SnackbarHelper.showError(context, 'Vui lòng nhập mã giảm giá');
      return;
    }

    Voucher? voucher;
    try {
      voucher = DataService.vouchers.firstWhere((v) => v.code.toUpperCase() == code && v.isActive);
    } catch (e) {
      voucher = null;
    }

    if (voucher == null) {
      if (showMessage) SnackbarHelper.showError(context, 'Mã không hợp lệ hoặc đã hết hạn');
      return;
    }

    if (Cart.totalAmount < voucher.minPurchase) {
      final diff = voucher.minPurchase - Cart.totalAmount;
      if (showMessage) {
        SnackbarHelper.showError(context, 'Đơn hàng chưa đạt mức tối thiểu ${FormatHelper.formatPrice(voucher.minPurchase)} (Còn thiếu ${FormatHelper.formatPrice(diff)})');
      }
      return;
    }

    setState(() {
      _voucherController.text = voucher!.code;
      _appliedVoucherCode = voucher.code;
      _discountAmount = voucher.discountAmount;
    });
    FocusScope.of(context).unfocus();
    if (showMessage) SnackbarHelper.showSuccess(context, 'Áp dụng mã ${voucher.code} thành công (-${FormatHelper.formatPrice(voucher.discountAmount)})!');
  }

  void _showVoucherPickerModal() {
    final vouchers = DataService.vouchers.where((v) => v.isActive).toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chọn mã giảm giá / Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (vouchers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('Hiện không có mã voucher nào khả dụng.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final v = vouchers[index];
                      final isEligible = Cart.totalAmount >= v.minPurchase;
                      final isSelected = _appliedVoucherCode == v.code;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : (isEligible ? Colors.white : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.green : (isEligible ? Colors.grey.shade300 : Colors.grey.shade200),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isEligible ? Colors.orange.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.local_offer, color: isEligible ? Colors.orange : Colors.grey, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(v.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '-${FormatHelper.formatPrice(v.discountAmount)}',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(v.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEligible
                                        ? 'Đơn tối thiểu: ${FormatHelper.formatPrice(v.minPurchase)}'
                                        : 'Cần mua thêm ${FormatHelper.formatPrice(v.minPurchase - Cart.totalAmount)} để áp dụng',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isEligible ? Colors.grey.shade600 : Colors.red.shade400,
                                      fontWeight: isEligible ? FontWeight.normal : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _appliedVoucherCode = null;
                                    _discountAmount = 0.0;
                                    _voucherController.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: const Text('Bỏ chọn', style: TextStyle(fontSize: 12)),
                              )
                            else
                              ElevatedButton(
                                onPressed: isEligible
                                    ? () {
                                        Navigator.pop(context);
                                        _applyVoucherCode(v.code);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Dùng mã', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _promptAddAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAddressesScreen(isSelecting: true)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _processPayment() async {
    if (!AuthService.isLoggedIn) {
      SnackbarHelper.showError(context, 'Vui lòng đăng nhập để tiến hành mua hàng!');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(redirectToCheckout: true)),
      ).then((_) {
        if (mounted) setState(() {});
      });
      return;
    }

    final addresses = StorageService.getAddresses();
    if (addresses.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng thêm địa chỉ giao hàng thì mới có thể đặt hàng!');
      _promptAddAddress();
      return;
    }

    final selectedAddr = addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first);
    final userAddress = selectedAddr['address']?.toString() ?? '';
    if (userAddress.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Địa chỉ giao hàng không hợp lệ. Vui lòng thêm lại địa chỉ!');
      _promptAddAddress();
      return;
    }

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
    if (!AuthService.isLoggedIn) {
      setState(() => _isProcessing = false);
      SnackbarHelper.showError(context, 'Vui lòng đăng nhập để tiến hành mua hàng!');
      return;
    }

    final addresses = StorageService.getAddresses();
    if (addresses.isEmpty) {
      setState(() => _isProcessing = false);
      SnackbarHelper.showError(context, 'Vui lòng thêm địa chỉ giao hàng thì mới có thể đặt hàng!');
      _promptAddAddress();
      return;
    }

    final selectedAddr = addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first);
    final userAddress = selectedAddr['address']?.toString() ?? '';
    if (userAddress.trim().isEmpty) {
      setState(() => _isProcessing = false);
      SnackbarHelper.showError(context, 'Địa chỉ giao hàng không hợp lệ. Vui lòng thêm lại địa chỉ!');
      _promptAddAddress();
      return;
    }

    // Generate order summary string from cart items
    final itemNames = Cart.items.map((i) => '${i.product.name} (x${i.quantity})').join(' + ');
    final orderId = 'DH${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final double finalTotal = (Cart.totalAmount - _discountAmount > 0 ? Cart.totalAmount - _discountAmount : 0);

    final userPhone = selectedAddr['phone']?.toString() ?? (AuthService.currentUser?.phone ?? '0912345678');

    final order = Order(
      id: orderId,
      customerName: AuthService.userName ?? 'Khách hàng',
      customerEmail: AuthService.userEmail,
      customerPhone: userPhone,
      address: userAddress,
      totalAmount: finalTotal,
      itemsSummary: itemNames,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    // Lưu vào MongoDB traicay_db thông qua DataService
    await DataService.addOrder(order);

    // Lưu vào StorageService cache cục bộ theo tài khoản
    await StorageService.addOrder({
      'id': orderId,
      'status': 'Đang xử lý',
      'items': itemNames,
      'date': 'Vừa xong',
      'total': FormatHelper.formatPrice(finalTotal),
      'customerEmail': AuthService.userEmail,
      'address': userAddress,
      'phone': userPhone,
    }, userEmail: AuthService.userEmail);

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
            Text(
              'Mã đơn hàng: #$orderId\nĐơn hàng đã được lưu vào hệ thống và đang được xử lý.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
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
              Builder(
                builder: (context) {
                  final addresses = StorageService.getAddresses();
                  final bool hasAddress = addresses.isNotEmpty;
                  final defaultAddr = hasAddress
                      ? addresses.firstWhere((a) => a['isDefault'] == true, orElse: () => addresses.first)
                      : null;
                  final displayName = AuthService.userName ?? "Khách hàng";
                  final displayPhone = defaultAddr?['phone'] ?? AuthService.currentUser?.phone ?? "0912345678";
                  final displayAddress = defaultAddr?['address']?.toString() ?? '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thông tin giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _promptAddAddress,
                            icon: Icon(hasAddress ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined, size: 16, color: Colors.green),
                            label: Text(hasAddress ? 'Thay đổi' : 'Thêm địa chỉ', style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!hasAddress) ...[
                        InkWell(
                          onTap: _promptAddAddress,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade400, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_location_alt, color: Colors.orange, size: 28),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chưa có địa chỉ giao hàng',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Nhấn vào đây để thêm địa chỉ giao hàng (Bắt buộc để đặt hàng)',
                                        style: TextStyle(color: Colors.black87, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withValues(alpha: 0.05), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$displayName • $displayPhone',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      defaultAddr?['title']?.toString() ?? 'Mặc định',
                                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(
                                  displayAddress,
                                  style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Khuyến mãi / Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _showVoucherPickerModal,
                    icon: const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.green),
                    label: const Text('Chọn Voucher', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Nhập mã giảm giá (VD: WELCOME10)',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              isDense: true,
                              prefixIcon: const Icon(Icons.local_offer_outlined, color: Colors.orange, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _applyVoucherCode(_voucherController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Áp dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_appliedVoucherCode != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã áp dụng mã $_appliedVoucherCode: Giảm -${FormatHelper.formatPrice(_discountAmount)}',
                                style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _appliedVoucherCode = null;
                                  _discountAmount = 0.0;
                                  _voucherController.clear();
                                });
                                SnackbarHelper.showSuccess(context, 'Đã hủy áp dụng mã voucher');
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close, color: Colors.red, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bảng tóm tắt thanh toán (Payment Summary)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiết thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính tiền hàng', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text(FormatHelper.formatPrice(Cart.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phí giao hàng', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text('Miễn phí', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    if (_discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Giảm giá Voucher (', style: TextStyle(color: Colors.green, fontSize: 14)),
                              Text('$_appliedVoucherCode', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                              const Text(')', style: TextStyle(color: Colors.green, fontSize: 14)),
                            ],
                          ),
                          Text('-${FormatHelper.formatPrice(_discountAmount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          FormatHelper.formatPrice(Cart.totalAmount - _discountAmount > 0 ? Cart.totalAmount - _discountAmount : 0),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
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
              Builder(
                builder: (context) {
                  final hasAddress = StorageService.getAddresses().isNotEmpty;
                  return SizedBox(
                    width: hasAddress ? 150 : 165,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasAddress ? Colors.green : Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              hasAddress ? 'Đặt hàng' : 'Thêm địa chỉ',
                              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
