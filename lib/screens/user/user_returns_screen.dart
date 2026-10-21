import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../models/order.dart';

class UserReturnsScreen extends StatefulWidget {
  const UserReturnsScreen({super.key});

  @override
  State<UserReturnsScreen> createState() => _UserReturnsScreenState();
}

class _UserReturnsScreenState extends State<UserReturnsScreen> {
  String? _selectedOrder;
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    final completedOrders = DataService.getOrdersForCustomer(AuthService.userEmail)
        .where((o) => o.status == OrderStatus.completed)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Yêu cầu đổi/trả', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn đơn hàng cần đổi/trả',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: completedOrders.any((o) => o.id == _selectedOrder) ? _selectedOrder : null,
                  hint: Text(
                    completedOrders.isEmpty
                        ? 'Bạn chưa có đơn hàng đã hoàn thành để đổi/trả'
                        : 'Chọn mã đơn hàng',
                    style: TextStyle(color: completedOrders.isEmpty ? Colors.grey : Colors.black87),
                  ),
                  items: completedOrders
                      .map((o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              'Đơn #${o.id} - ${o.itemsSummary.isNotEmpty ? o.itemsSummary : 'Sản phẩm'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: completedOrders.isEmpty
                      ? null
                      : (value) => setState(() => _selectedOrder = value),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Lý do đổi/trả',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: ['Sản phẩm bị dập nát/hư hỏng', 'Giao sai sản phẩm', 'Sản phẩm không giống mô tả', 'Khác'].contains(_selectedReason)
                      ? _selectedReason
                      : null,
                  hint: const Text('Chọn lý do'),
                  items: [
                    'Sản phẩm bị dập nát/hư hỏng',
                    'Giao sai sản phẩm',
                    'Sản phẩm không giống mô tả',
                    'Khác'
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => _selectedReason = value),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chi tiết thêm (Không bắt buộc)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết tình trạng...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hình ảnh minh chứng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, style: BorderStyle.solid),
                  ),
                  child: const Center(child: Icon(Icons.add_a_photo, color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yêu cầu đã được gửi. Chúng tôi sẽ phản hồi sớm nhất.'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
