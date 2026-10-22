import 'package:flutter/material.dart';
import '../../models/voucher.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';

class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  void _confirmDeleteVoucher(Voucher v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa Voucher'),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn mã voucher "${v.code}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DataService.deleteVoucher(v.code);
              setState(() {});
              SnackbarHelper.showSuccess(context, 'Đã xóa voucher ${v.code}');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openEditVoucherDialog(Voucher v) {
    final descController = TextEditingController(text: v.description);
    final discountController = TextEditingController(text: v.discountAmount.toStringAsFixed(0));
    final minPurchaseController = TextEditingController(text: v.minPurchase.toStringAsFixed(0));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.edit_note, color: Colors.orange.shade700),
              ),
              const SizedBox(width: 12),
              Text('Cập nhật mã ${v.code}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả khuyến mãi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (ctx, setFieldState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Loại giảm giá:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'fixed', label: Text('Cố định (₫)'), icon: Icon(Icons.attach_money)),
                            ButtonSegment(value: 'percentage', label: Text('Phần trăm (%)'), icon: Icon(Icons.percent)),
                          ],
                          selected: {discountType},
                          onSelectionChanged: (set) {
                            setFieldState(() => discountType = set.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (discountType == 'fixed')
                          TextField(
                            controller: discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Số tiền giảm (₫)', border: OutlineInputBorder()),
                          )
                        else
                          TextField(
                            controller: percentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Phần trăm giảm (1 - 100%)', border: OutlineInputBorder()),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Field discount
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền giảm (₫)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minPurchaseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đơn hàng tối thiểu (₫)', helperText: 'Đơn phải đạt giá trị này mới áp dụng được mã', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final discount = double.tryParse(discountController.text) ?? 0.0;
                final minPurchase = double.tryParse(minPurchaseController.text) ?? 0.0;
                final updated = v.copyWith(
                  description: descController.text.trim(),
                  discountAmount: discount,
                  minPurchase: minPurchase,
                );
                await DataService.updateVoucher(v.code, updated);
                if (!mounted) return;
                Navigator.pop(ctx);
                setState(() {});
                SnackbarHelper.showSuccess(context, 'Đã cập nhật thông tin mã ${v.code}');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Cập nhật', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openAddVoucherDialog() {
    final codeController = TextEditingController();
    final descController = TextEditingController();
    String discountType = 'fixed';
    final percentController = TextEditingController(text: '10');
    final discountController = TextEditingController(text: '20000');
    final minPurchaseController = TextEditingController(text: '100000');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.add_card, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              const Text('Thêm Voucher mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã voucher (VD: WELCOME10)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả khuyến mãi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền giảm (₫)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minPurchaseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Đơn hàng tối thiểu (₫)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim().toUpperCase();
                final desc = descController.text.trim();
                final discount = double.tryParse(discountController.text) ?? 0.0;
                final minPurchase = double.tryParse(minPurchaseController.text) ?? 0.0;

                if (code.isEmpty || discount <= 0) {
                  SnackbarHelper.showError(context, 'Vui lòng nhập đầy đủ mã và số tiền giảm hợp lệ');
                  return;
                }

                final newVoucher = Voucher(
                  code: code,
                  description: desc.isNotEmpty ? desc : 'Giảm ${discount.toStringAsFixed(0)}₫',
                  discountAmount: discountType == 'fixed' ? discount : 0.0,
                  discountPercentage: discountType == 'percentage' ? (double.tryParse(percentController.text) ?? 10.0) : 0.0,
                  discountType: discountType,
                  minPurchase: minPurchase,
                  isActive: true,
                );

                await DataService.addVoucher(newVoucher);
                if (!mounted) return;
                Navigator.pop(ctx);
                setState(() {});
                SnackbarHelper.showSuccess(context, 'Tạo mã voucher ${newVoucher.code} thành công!');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Tạo mã', style: TextStyle(color: Colors.white)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
            tooltip: 'Thêm Voucher',
            onPressed: _openAddVoucherDialog,
          ),
        ],
      ),
      body: DataService.vouchers.isEmpty
          ? const Center(child: Text('Chưa có voucher nào. Nhấn + để tạo mới.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: DataService.vouchers.length,
              itemBuilder: (ctx, index) {
                final v = DataService.vouchers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.local_offer, color: Colors.white)),
                    title: Text(v.code, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    subtitle: Text('${v.description}\nGiảm: ${v.discountAmount.toStringAsFixed(0)}₫ - Đơn từ: ${v.minPurchase.toStringAsFixed(0)}₫'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: v.isActive,
                          activeColor: Colors.green,
                          onChanged: (val) async {
                            await DataService.toggleVoucherStatus(v.code, val);
                            setState(() {});
                            SnackbarHelper.showSuccess(context, val ? 'Đã kích hoạt ${v.code}' : 'Đã vô hiệu hóa ${v.code}');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Chỉnh sửa voucher',
                          onPressed: () => _openEditVoucherDialog(v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Xóa voucher',
                          onPressed: () => _confirmDeleteVoucher(v),
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
