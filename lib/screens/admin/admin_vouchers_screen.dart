import 'package:flutter/material.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../user/user_vouchers_screen.dart';

class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  void _addVoucher() {
    final codeController = TextEditingController();
    final descController = TextEditingController();
    final discountController = TextEditingController();
    final minPurchaseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm Voucher mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Mã giảm giá (VD: FREESHIP50)')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
                TextField(controller: discountController, decoration: const InputDecoration(labelText: 'Số tiền giảm (\$)'), keyboardType: TextInputType.number),
                TextField(controller: minPurchaseController, decoration: const InputDecoration(labelText: 'Đơn tối thiểu (\$)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text;
                final desc = descController.text;
                final discount = double.tryParse(discountController.text) ?? 0.0;
                final minPurchase = double.tryParse(minPurchaseController.text) ?? 0.0;

                if (code.isNotEmpty && discount > 0) {
                  final newVoucher = Voucher(
                    code: code,
                    description: desc,
                    discountAmount: discount,
                    minPurchase: minPurchase,
                  );
                  await DataService.addVoucher(newVoucher);
                  if (!context.mounted) return;
                  setState(() {});
                  Navigator.pop(context);
                  SnackbarHelper.showSuccess(context, 'Thêm voucher thành công');
                } else {
                  SnackbarHelper.showError(context, 'Vui lòng nhập mã và số tiền giảm');
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet_outlined),
            tooltip: 'Ví Voucher (User)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserVouchersScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm Voucher',
            onPressed: _addVoucher,
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: DataService.vouchers.length,
        itemBuilder: (context, index) {
          final voucher = DataService.vouchers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              subtitle: Text('${voucher.description}\nGiảm: \$${voucher.discountAmount} - Đơn từ: \$${voucher.minPurchase}'),
              isThreeLine: true,
              trailing: Switch(
                value: voucher.isActive,
                onChanged: (val) {
                  // In real app, update state of voucher
                  SnackbarHelper.showSuccess(context, 'Đã cập nhật trạng thái');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
