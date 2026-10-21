import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/sign_out_dialog.dart';
import 'user_orders_screen.dart';
import 'user_addresses_screen.dart';
import 'user_payment_methods_screen.dart';
import 'user_support_chat_screen.dart';
import 'user_returns_screen.dart';
import 'user_edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cá nhân', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      (AuthService.userName ?? 'K').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AuthService.userName ?? 'Khách',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Thành viên Vàng',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserEditProfileScreen())
                      );
                      if (updated == true) {
                        setState(() {}); // Refresh the profile name
                      }
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Menu Items
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuCard([
                    _buildMenuItem(context, Icons.shopping_bag_outlined, 'Đơn hàng của tôi', 'Quản lý đơn hàng và theo dõi vận chuyển', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserOrdersScreen()));
                    }),
                    const Divider(height: 1, indent: 60),
                    _buildMenuItem(context, Icons.location_on_outlined, 'Địa chỉ giao hàng', 'Thiết lập địa chỉ nhận hàng', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAddressesScreen()));
                    }),
                    const Divider(height: 1, indent: 60),
                    _buildMenuItem(context, Icons.payment_outlined, 'Phương thức thanh toán', 'Thẻ tín dụng, Ví điện tử', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPaymentMethodsScreen()));
                    }),
                  ]),
                  const SizedBox(height: 20),
                  _buildMenuCard([
                    _buildMenuItem(context, Icons.support_agent_outlined, 'Trò chuyện & Hỗ trợ', 'Liên hệ với CSKH', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserSupportChatScreen()));
                    }),
                    const Divider(height: 1, indent: 60),
                    _buildMenuItem(context, Icons.assignment_return_outlined, 'Yêu cầu đổi/trả', 'Xử lý khiếu nại đơn hàng', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserReturnsScreen()));
                    }),
                  ]),
                  const SizedBox(height: 20),
                  _buildMenuCard([
                    _buildMenuItem(
                      context, 
                      Icons.logout, 
                      'Đăng xuất', 
                      'Thoát khỏi tài khoản hiện tại', 
                      () {
                        showSignOutDialog(context);
                      },
                      isDestructive: true,
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;
    final iconColor = isDestructive ? Colors.redAccent : Colors.green;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

}
