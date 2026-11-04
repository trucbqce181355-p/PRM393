import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../admin/admin_dashboard_screen.dart';
import 'user_home_screen.dart';
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
    final isAdmin = AuthService.isAdmin;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Cá nhân (Admin)' : 'Cá nhân',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
                gradient: LinearGradient(
                  colors: isAdmin
                      ? [const Color(0xFF1B5E20), const Color(0xFF4CAF50)]
                      : [Colors.green, Colors.lightGreen],
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
                      isAdmin ? 'A' : (AuthService.userName ?? 'K').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? const Color(0xFF1B5E20) : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'Admin' : (AuthService.userName ?? 'Khách'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            if (isAdmin) {
                              return const Text(
                                'admin@gmail.com • Quản trị viên',
                                style: TextStyle(fontSize: 14, color: Colors.white70),
                              );
                            }
                            final email = AuthService.userEmail ?? 'Chưa đăng nhập';
                            final tier = DataService.getCustomerMemberTier(email);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tier == 'Vàng'
                                            ? Icons.workspace_premium
                                            : (tier == 'Bạc' ? Icons.military_tech : Icons.stars),
                                        size: 14,
                                        color: Colors.amberAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Hạng $tier',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (!isAdmin)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UserEditProfileScreen()),
                        );
                        if (updated == true) {
                          setState(() {}); // Refresh the profile name
                        }
                      },
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Stats Card (if logged in customer)
            if (!isAdmin && AuthService.userEmail != null && AuthService.userEmail!.isNotEmpty)
              Builder(
                builder: (context) {
                  final email = AuthService.userEmail!;
                  final realSpent = DataService.getCustomerTotalSpent(email);
                  final realOrders = DataService.getCustomerTotalOrders(email);
                  final realTier = DataService.getCustomerMemberTier(email);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Hạng thành viên', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              realTier,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade200),
                        Column(
                          children: [
                            const Text('Tổng chi tiêu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${realSpent.toStringAsFixed(0)}₫',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade200),
                        Column(
                          children: [
                            const Text('Tổng đơn hàng', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '$realOrders',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // Menu Items
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isAdmin
                  ? Column(
                      children: [
                        _buildMenuCard([
                          _buildMenuItem(
                            context,
                            Icons.lock_reset_rounded,
                            'Đổi mật khẩu',
                            'Thay đổi mật khẩu tài khoản Admin',
                            () {
                              _showChangePasswordDialog(context);
                            },
                          ),
                          const Divider(height: 1, indent: 60),
                          _buildMenuItem(
                            context,
                            Icons.admin_panel_settings_outlined,
                            'Về trang quản trị',
                            'Quay lại bảng điều khiển quản lý',
                            () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _buildMenuCard([
                          _buildMenuItem(
                            context,
                            Icons.logout,
                            'Đăng xuất',
                            'Thoát khỏi tài khoản quản trị',
                            () {
                              _showLogoutDialog(context);
                            },
                            isDestructive: true,
                          ),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMenuCard([
                          _buildMenuItem(context, Icons.shopping_bag_outlined, 'Đơn hàng của tôi',
                              'Quản lý đơn hàng và theo dõi vận chuyển', () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const UserOrdersScreen()));
                          }),
                          const Divider(height: 1, indent: 60),
                          _buildMenuItem(context, Icons.location_on_outlined, 'Địa chỉ giao hàng',
                              'Thiết lập địa chỉ nhận hàng', () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const UserAddressesScreen()));
                          }),
                          const Divider(height: 1, indent: 60),
                          _buildMenuItem(context, Icons.payment_outlined, 'Phương thức thanh toán',
                              'Thẻ tín dụng, Ví điện tử', () {
                            Navigator.push(
                                context, MaterialPageRoute(builder: (context) => const UserPaymentMethodsScreen()));
                          }),
                        ]),
                        const SizedBox(height: 20),
                        _buildMenuCard([
                          _buildMenuItem(
                              context, Icons.support_agent_outlined, 'Trò chuyện & Hỗ trợ', 'Liên hệ với CSKH', () {
                            Navigator.push(
                                context, MaterialPageRoute(builder: (context) => const UserSupportChatScreen()));
                          }),
                          const Divider(height: 1, indent: 60),
                          _buildMenuItem(
                              context, Icons.assignment_return_outlined, 'Yêu cầu đổi/trả', 'Xử lý khiếu nại đơn hàng', () {
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
                              _showLogoutDialog(context);
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

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
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

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset_rounded, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Đổi mật khẩu Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Text(
                        'Mật khẩu hiện tại',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: oldPasswordController,
                        obscureText: obscureOld,
                        decoration: InputDecoration(
                          hintText: 'Nhập mật khẩu hiện tại',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Mật khẩu mới',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Tối thiểu 6 ký tự',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Xác nhận mật khẩu mới',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Nhập lại mật khẩu mới',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final oldPass = oldPasswordController.text.trim();
                          final newPass = newPasswordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (oldPass.isEmpty) {
                            setDialogState(() => errorMessage = 'Vui lòng nhập mật khẩu hiện tại');
                            return;
                          }
                          if (newPass.length < 6) {
                            setDialogState(() => errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự');
                            return;
                          }
                          if (newPass != confirmPass) {
                            setDialogState(() => errorMessage = 'Mật khẩu xác nhận không khớp');
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          final success = await AuthService.changeAdminPassword(oldPass, newPass);

                          if (!dialogContext.mounted) return;

                          if (success) {
                            Navigator.pop(dialogContext);
                            SnackbarHelper.showSuccess(context, 'Đổi mật khẩu Admin thành công!');
                          } else {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'Mật khẩu hiện tại không chính xác!';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
