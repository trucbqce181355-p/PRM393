import 'package:flutter/material.dart';
import 'screens/admin/admin_vouchers_screen.dart';
import 'screens/user/user_vouchers_screen.dart';
import 'screens/user/checkout_screen.dart';
import 'screens/user/user_support_chat_screen.dart';
import 'screens/user/user_returns_screen.dart';
import 'services/data_service.dart';
import 'services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDBService.connect();
  await DataService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit App - Dev 4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const Dev4NavigationScreen(),
    );
  }
}

class Dev4NavigationScreen extends StatelessWidget {
  const Dev4NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dev 4: Voucher & Chat Hỗ Trợ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFlowHeader(
            '7. Flow Khuyến mãi & Voucher',
            'Admin tạo mã -> User lưu vào ví -> Checkout tính toán & trừ tiền',
            Icons.local_offer,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            title: '1. Admin Quản lý Voucher',
            subtitle: 'Tạo chiến dịch mã giảm giá (VD: FREESHIP50)',
            icon: Icons.admin_panel_settings,
            color: Colors.deepPurple,
            destination: const AdminVouchersScreen(),
          ),
          _buildActionCard(
            context,
            title: '2. Ví Voucher (User)',
            subtitle: 'Xem danh sách mã voucher khả dụng và sao chép mã',
            icon: Icons.wallet_giftcard,
            color: Colors.orange,
            destination: const UserVouchersScreen(),
          ),
          _buildActionCard(
            context,
            title: '3. Màn hình Checkout',
            subtitle: 'Tự động kiểm tra điều kiện tối thiểu và trừ tiền hóa đơn',
            icon: Icons.shopping_cart_checkout,
            color: Colors.green,
            destination: const CheckoutScreen(),
          ),
          const SizedBox(height: 24),
          _buildFlowHeader(
            '8. Flow Chat & Hỗ trợ',
            'User khiếu nại trái cây dập -> Chat gửi hình ảnh -> Xử lý đổi trả',
            Icons.support_agent,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            title: '1. Chat CSKH & Hỗ trợ',
            subtitle: 'Trò chuyện hỗ trợ khách hàng, gửi tin nhắn & hình ảnh',
            icon: Icons.chat_bubble_outline,
            color: Colors.blue,
            destination: const UserSupportChatScreen(),
          ),
          _buildActionCard(
            context,
            title: '2. Yêu cầu Đổi / Trả hàng',
            subtitle: 'Gửi yêu cầu khiếu nại sản phẩm dập nát kèm hình ảnh',
            icon: Icons.assignment_return_outlined,
            color: Colors.teal,
            destination: const UserReturnsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        },
      ),
    );
  }
}
