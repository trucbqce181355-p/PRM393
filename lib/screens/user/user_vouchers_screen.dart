import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import 'package:flutter/services.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/format_helper.dart';
import '../../models/cart_item.dart';
import 'checkout_screen.dart';

class UserVouchersScreen extends StatelessWidget {
  const UserVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vouchers = DataService.vouchers.where((v) => v.isActive).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ví Voucher', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: vouchers.isEmpty 
        ? const Center(child: Text('Bạn chưa có voucher nào.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_offer, color: Colors.orange.shade700, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  voucher.code,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    '-${FormatHelper.formatPrice(voucher.discountAmount)}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(voucher.description, style: TextStyle(color: Colors.grey[700])),
                            const SizedBox(height: 4),
                            Text('Đơn tối thiểu: ${FormatHelper.formatPrice(voucher.minPurchase)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (Cart.items.isEmpty) {
                                Clipboard.setData(ClipboardData(text: voucher.code));
                                SnackbarHelper.showSuccess(context, 'Đã copy mã ${voucher.code}. Hãy thêm sản phẩm vào giỏ hàng!');
                                Navigator.pop(context);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(initialVoucherCode: voucher.code),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Dùng ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                            tooltip: 'Copy mã',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: voucher.code));
                              SnackbarHelper.showSuccess(context, 'Đã copy mã: ${voucher.code}');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
