import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'otp_screen.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../user/user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _onRegisterPressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      SnackbarHelper.showError(context, 'Vui lòng nhập Email hợp lệ');
      return;
    }

    // Check duplicate email
    final isDuplicate = DataService.customers.any((c) => c.email == email);
    if (isDuplicate) {
      SnackbarHelper.showError(context, 'Email này đã được đăng ký!');
      return;
    }

    setState(() => _isLoading = true);
    String error = await AuthService.loginWithEmail(email);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error.isNotEmpty) {
      // Nếu có lỗi, hiện lên màn hình để dễ xem
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi gửi Email'),
          content: Text('Không thể gửi mail vì bị Google chặn xác thực (Sai mật khẩu hoặc cần App Password).\n\nChi tiết lỗi:\n$error\n\nMã OTP test (đã in ra console) vẫn hoạt động.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OtpScreen()),
                );
              },
              child: const Text('Tiếp tục nhập OTP Test'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OtpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo tài khoản mới',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập email để nhận mã OTP đăng ký',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onRegisterPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Nhận mã OTP',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
