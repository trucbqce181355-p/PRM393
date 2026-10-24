import 'package:flutter/material.dart';
import '../user/user_home_screen.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../utils/format_helper.dart';
import 'admin_orders_screen.dart';
import 'admin_vouchers_screen.dart';
import 'admin_products_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_returns_screen.dart';
import 'admin_chat_screen.dart';

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
    final totalCustomers = DataService.customers.length;
    final totalOrders = DataService.orders.length;
    final pendingReturns = DataService.returnRequests.where((r) => r.status == 'pending').length;
    final lowStockCount = DataService.getLowStockProducts(10).length;
    final unrepliedReviews = DataService.reviews.where((r) => r.adminReply == null || r.adminReply!.trim().isEmpty).length;
    final unreadChatCount = DataService.chatMessages.where((m) => !m.isRead && m.senderRole == 'user').length;

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
                    'Doanh thu tháng',
                    FormatHelper.formatPrice(28450000),
                    '+12.5%',
                    Colors.green.shade700,
                    Icons.monetization_on_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Đơn hàng',
                    totalOrders > 0 ? '$totalOrders' : '1.892',
                    '+8.1%',
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

            const SizedBox(height: 24),
            const Text(
              'Chức năng quản trị hệ thống',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Feature Grid Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildActionCard(
                  title: 'Quản lý kho hàng',
                  subtitle: lowStockCount > 0 ? '$lowStockCount cảnh báo hết hàng' : '5 chức năng: Nhập/Xuất/Kiểm kê',
                  icon: Icons.warehouse_rounded,
                  color: Colors.indigo,
                  badge: lowStockCount > 0 ? '$lowStockCount' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInventoryScreen())),
                ),
                _buildActionCard(
                  title: 'Quản lý đơn hàng',
                  subtitle: 'Gói xong / Gán Shipper / Hủy đơn',
                  icon: Icons.local_shipping_rounded,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen())),
                ),
                _buildActionCard(
                  title: 'Khiếu nại & Đổi trả',
                  subtitle: pendingReturns > 0 ? '$pendingReturns yêu cầu chờ duyệt' : 'Xử lý đổi trả hoàn tiền',
                  icon: Icons.assignment_return_rounded,
                  color: Colors.deepOrange,
                  badge: pendingReturns > 0 ? '$pendingReturns' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReturnsScreen())),
                ),
                _buildActionCard(
                  title: 'Đánh giá & Phản hồi',
                  subtitle: unrepliedReviews > 0 ? '$unrepliedReviews chưa trả lời' : 'Ẩn review, trả lời đánh giá',
                  icon: Icons.rate_review_rounded,
                  color: Colors.amber.shade800,
                  badge: unrepliedReviews > 0 ? '$unrepliedReviews' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewsScreen())),
                ),
                _buildActionCard(
                  title: 'Danh mục sản phẩm',
                  subtitle: '${DataService.categories.length} phân loại trái cây',
                  icon: Icons.category_rounded,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoriesScreen())),
                ),
                _buildActionCard(
                  title: 'Voucher & Giảm giá',
                  subtitle: 'Cấu hình % hoặc tiền mặt',
                  icon: Icons.local_offer_rounded,
                  color: Colors.pink,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVouchersScreen())),
                ),
                _buildActionCard(
                  title: 'Quản lý sản phẩm',
                  subtitle: '$activeProducts mặt hàng đang kinh doanh',
                  icon: Icons.apple_rounded,
                  color: Colors.green.shade700,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsScreen())),
                ),
                _buildActionCard(
                  title: 'Hỗ trợ & Chat CSKH',
                  subtitle: unreadChatCount > 0 ? '$unreadChatCount tin nhắn mới cần trả lời' : 'Chat trực tuyến, tư vấn khách',
                  icon: Icons.support_agent_rounded,
                  color: Colors.cyan.shade800,
                  badge: unreadChatCount > 0 ? '$unreadChatCount' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChatScreen())),
                ),
                _buildActionCard(
                  title: 'Quản lý khách hàng',
                  subtitle: '$totalCustomers tài khoản thành viên',
                  icon: Icons.people_alt_rounded,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCustomersScreen())),
                ),
              ],
            ),
            const SizedBox(height: 20),
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

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
