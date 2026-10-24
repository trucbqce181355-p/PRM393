import 'package:flutter/material.dart';

/// Shows the app's simulated confirmation sheet for MoMo and VNPay payments.
class PaymentGatewaySheet {
  const PaymentGatewaySheet._();

  static Future<void> show({
    required BuildContext context,
    required String provider,
    required Future<void> Function() onSuccess,
  }) {
    final isMomo = provider == 'MOMO';
    final providerName = isMomo ? 'MoMo' : 'VNPay';
    final logoUrl = isMomo
        ? 'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png'
        : 'https://vnpay.vn/s1/statics.vnpay.vn/2023/9/06ncktiwd6dc1694418196384.png';

    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(logoUrl, height: 60),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.pink),
            const SizedBox(height: 24),
            Text(
              'Đang chờ thanh toán qua $providerName...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng xác nhận trên ứng dụng của bạn.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(sheetContext);
                await onSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mô phỏng: Đã thanh toán thành công',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
