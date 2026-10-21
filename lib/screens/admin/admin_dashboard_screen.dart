import 'package:flutter/material.dart';
import '../../utils/sign_out_dialog.dart';
import '../../services/data_service.dart';
import 'admin_add_product_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_vouchers_screen.dart';
import 'admin_products_screen.dart';
import 'admin_customers_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF252538),
        title: const Text(
          'Fruitopia Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => showSignOutDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF252538),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E1E2C),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text('Admin HTran', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text('htran@fruitopia.com', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Tổng quan', true, () {}),
            _buildDrawerItem(Icons.inventory_2, 'Sản phẩm', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProductsScreen()));
            }),
            _buildDrawerItem(Icons.shopping_bag, 'Đơn hàng', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminOrdersScreen()));
            }),
            _buildDrawerItem(Icons.local_offer, 'Voucher', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminVouchersScreen()));
            }),
            _buildDrawerItem(Icons.people, 'Khách hàng', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCustomersScreen()));
            }),
            _buildDrawerItem(Icons.settings, 'Cài đặt', false, () {}),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
              onTap: () => showSignOutDialog(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan báo cáo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary Cards
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Doanh thu', '\$28,450', '+12.5%', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Đơn hàng', '1,892', '+8.1%', Colors.blue)),
              ],
            ),
            const SizedBox(height: 24),
            // Thêm các biểu đồ hoặc nội dung tổng quan khác vào đây trong tương lai
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.greenAccent : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
      tileColor: isSelected ? Colors.white.withOpacity(0.05) : null,
      onTap: onTap,
    );
  }

  Widget _buildSummaryCard(String title, String value, String change, Color trendColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.arrow_upward, color: trendColor, size: 14),
              const SizedBox(width: 4),
              Text(change, style: TextStyle(color: trendColor, fontSize: 12)),
              const Text(' this month', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProductListItem(String name, String category, String price, String status, Color statusColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Colors.grey),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
