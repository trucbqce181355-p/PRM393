import 'package:flutter/material.dart';
import '../user/user_home_screen.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../utils/format_helper.dart';
import '../../models/order.dart';
import 'admin_orders_screen.dart';
import 'admin_vouchers_screen.dart';
import 'admin_products_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_returns_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_banners_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final activeProducts = DataService.products.where((p) => p.isDeleted != true).length;
    final activeVouchers = DataService.vouchers.where((v) => v.isActive).length;
    final totalOrders = DataService.orders.length;
    final lowStockCount = DataService.getLowStockProducts(10).length;
    final validOrders = DataService.orders.where((o) => o.status != OrderStatus.cancelled).toList();
    final realRevenue = validOrders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
    final pendingOrdersCount = DataService.orders.where((o) => o.status == OrderStatus.pending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: const Text(
          'Fruitopia Admin',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_rounded, color: Colors.blue),
            tooltip: 'Về trang chủ',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: () {
              AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings_rounded, color: Colors.green.shade700, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Quản trị viên',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'admin@gmail.com',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.dashboard_rounded, 'Tổng quan', true, () {
                Navigator.pop(context);
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.warehouse_rounded, 'Quản lý kho hàng', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminInventoryScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.shopping_bag_rounded, 'Quản lý đơn hàng', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminOrdersScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.assignment_return_rounded, 'Khiếu nại / Đổi trả', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReturnsScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.inventory_2_rounded, 'Sản phẩm trái cây', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProductsScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.category_rounded, 'Danh mục sản phẩm', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCategoriesScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.rate_review_rounded, 'Đánh giá & Phản hồi', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReviewsScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.local_offer_rounded, 'Khuyến mãi / Voucher', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminVouchersScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.view_carousel_rounded, 'Banner theo mùa', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBannersScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.support_agent_rounded, 'Hỗ trợ & Chat trực tuyến', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminChatScreen()));
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildDrawerItem(Icons.people_alt_rounded, 'Khách hàng', false, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCustomersScreen()));
              }),
            ),
            const Divider(height: 20, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.storefront_rounded, color: Colors.blue),
                title: const Text('Về trang chủ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.blue.shade50.withOpacity(0.5),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.red.shade50.withOpacity(0.5),
                onTap: () {
                  AuthService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
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
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Top Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Doanh thu',
                    FormatHelper.formatPrice(realRevenue),
                    validOrders.isNotEmpty ? '${validOrders.length} đơn hợp lệ' : 'Chưa có doanh thu',
                    Colors.green.shade700,
                    Icons.monetization_on_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Đơn hàng',
                    '$totalOrders',
                    pendingOrdersCount > 0 ? '$pendingOrdersCount đơn chờ xử lý' : 'Tất cả đơn hàng',
                    Colors.blue.shade700,
                    Icons.shopping_bag_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Sản phẩm',
                    '$activeProducts',
                    lowStockCount > 0 ? '$lowStockCount quả sắp hết' : 'Đang bán',
                    lowStockCount > 0 ? Colors.red.shade700 : Colors.purple.shade700,
                    Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Voucher đang chạy',
                    '$activeVouchers',
                    'Đang kích hoạt',
                    Colors.orange.shade700,
                    Icons.local_offer_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green.shade800 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      tileColor: isSelected ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
