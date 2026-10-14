import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../admin/admin_dashboard_screen.dart';
import '../user/user_home_screen.dart';
import 'otp_screen.dart';
import 'profile_setup_screen.dart';
import 'register_screen.dart';

/// Bước 2: Chọn đăng nhập bằng Google hoặc Số điện thoại (SĐT)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoadingGoogle = false;
  bool _isLoadingPhone = false;
  bool _isLoadingEmail = false;
  bool _showEmailLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 2.1 ĐĂNG NHẬP BẰNG GOOGLE ---
  Future<void> _handleGoogleLogin() async {
    if (_isLoadingEmail || _isLoadingGoogle || _isLoadingPhone) return;
    setState(() => _isLoadingGoogle = true);
    try {
      final result = await AuthService.loginWithGoogle();
      if (!mounted) return;
      setState(() => _isLoadingGoogle = false);

      final isNewUser = result['isNewUser'] as bool;
      if (isNewUser) {
        // Chuyển sang điền hồ sơ (Tên, Email)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              prefilledName: result['name'] as String?,
              prefilledEmail: result['email'] as String?,
              authMethod: 'google',
            ),
          ),
        );
      } else {
        SnackbarHelper.showSuccess(context, 'Đăng nhập Google thành công!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGoogle = false);
      SnackbarHelper.showError(context, 'Lỗi đăng nhập Google: $e');
    }
  }

  // --- 2.2 ĐĂNG NHẬP BẰNG SỐ ĐIỆN THOẠI (GỬI OTP) ---
  Future<void> _handlePhoneLogin() async {
    if (_isLoadingEmail || _isLoadingGoogle || _isLoadingPhone) return;
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập số điện thoại');
      return;
    }

    // Validate số điện thoại VN (10 chữ số, bắt đầu bằng 0)
    final phoneRegex = RegExp(r'^0[3|5|7|8|9][0-9]{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      SnackbarHelper.showError(
        context,
        'Số điện thoại không hợp lệ (Phải có 10 chữ số, bắt đầu bằng 03, 05, 07, 08, 09)',
      );
      return;
    }

    setState(() => _isLoadingPhone = true);
    try {
      final otp = await AuthService.sendPhoneOtp(phone);
      if (!mounted) return;
      setState(() => _isLoadingPhone = false);

      SnackbarHelper.showSuccess(
        context,
        'Đã gửi mã OTP đến $phone. Mã thử nghiệm: $otp (hoặc 123456)',
      );

      // Chuyển tiếp sang màn hình Xác minh OTP
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpScreen(phone: phone)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPhone = false);
      SnackbarHelper.showError(context, 'Không thể gửi OTP: $e');
    }
  }

  // --- ĐĂNG NHẬP ADMIN / EMAIL (DỰ PHÒNG) ---
  Future<void> _handleEmailPasswordLogin() async {
    if (_isLoadingEmail || _isLoadingGoogle || _isLoadingPhone) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng điền Email và Mật khẩu');
      return;
    }

    setState(() => _isLoadingEmail = true);
    try {
      final role = await AuthService.login(email, password);
      if (!mounted) return;
      setState(() => _isLoadingEmail = false);

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingEmail = false);
      SnackbarHelper.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo & App Name
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, size: 45, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fruitopia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nông sản tươi ngon giao tận tay bạn',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 36),

              // Card Đăng nhập chính
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Đăng nhập tài khoản',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chọn đăng nhập nhanh bằng Google hoặc Số điện thoại để bắt đầu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // 1. NÚT ĐĂNG NHẬP BẰNG GOOGLE
                    OutlinedButton(
                      onPressed: _isLoadingGoogle ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: _isLoadingGoogle
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F3F4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    'G',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Tiếp tục với Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),
                    // Hoặc ngăn cách
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'HOẶC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. NHẬP SỐ ĐIỆN THOẠI & GỬI OTP
                    const Text(
                      'Số điện thoại của bạn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 0987654321',
                        prefixIcon: const Icon(
                          Icons.phone_android,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9F7),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoadingPhone ? null : _handlePhoneLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoadingPhone
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Gửi mã xác thực OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Toggle Form Admin / Mật khẩu
              TextButton.icon(
                onPressed: () {
                  setState(() => _showEmailLogin = !_showEmailLogin);
                },
                icon: Icon(
                  _showEmailLogin
                      ? Icons.keyboard_arrow_up
                      : Icons.admin_panel_settings_outlined,
                  color: Colors.black54,
                  size: 18,
                ),
                label: Text(
                  _showEmailLogin
                      ? 'Ẩn đăng nhập Email'
                      : 'Đăng nhập bằng Email & Mật khẩu',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),

              if (_showEmailLogin) ...[
                TextButton(
                  onPressed:
                      _isLoadingEmail || _isLoadingGoogle || _isLoadingPhone
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoadingEmail
                              ? null
                              : _handleEmailPasswordLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoadingEmail
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Đăng nhập Email'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
