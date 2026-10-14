import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF252538),
        title: const Text(
          'Quản lý Khách hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252538),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khách hàng (Tên, SĐT, Email)...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Customer List
            const Text(
              'Danh sách Khách hàng',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252538),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: DataService.customers.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final customer = DataService.customers[index];
                  
                  Color tierColor;
                  switch(customer.memberTier) {
                    case 'Vàng': tierColor = Colors.amber; break;
                    case 'Bạc': tierColor = Colors.grey.shade400; break;
                    case 'Bạch Kim': tierColor = Colors.blue.shade200; break;
                    default: tierColor = Colors.brown.shade300; break;
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: tierColor.withOpacity(0.2),
                      child: Text(
                        customer.name.substring(0, 1),
                        style: TextStyle(color: tierColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customer.memberTier,
                            style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${customer.phone} - ${customer.email}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Đã chi tiêu: \$${customer.totalSpent.toStringAsFixed(2)} (${customer.totalOrders} đơn)', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                    trailing: Switch(
                      value: customer.isActive,
                      activeColor: Colors.green,
                      onChanged: (val) async {
                        await DataService.updateCustomerStatus(customer.id, val);
                        setState(() {});
                        if (mounted) {
                          SnackbarHelper.showSuccess(context, 'Cập nhật trạng thái thành công');
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
