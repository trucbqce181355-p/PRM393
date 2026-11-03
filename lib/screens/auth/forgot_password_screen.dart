import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Nhập Email, 2: Nhập OTP, 3: Tạo Mật khẩu mới
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      SnackbarHelper.showError(context, 'Vui lòng nhập Email hợp lệ');
      return;
    }

    // Bắt lỗi email chưa đăng ký
    final exists = DataService.customers.any((c) => c.email == email);
    if (!exists) {
      SnackbarHelper.showError(context, 'Email này chưa được đăng ký!');
      return;
    }

    setState(() => _isLoading = true);
    String error = await AuthService.loginWithEmail(email);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error.isNotEmpty) {
      SnackbarHelper.showError(context, 'Lỗi gửi mail: \$error');
      // Vẫn cho qua bước 2 để test nếu lỗi Google (khi test không có App Password)
      setState(() => _currentStep = 2);
    } else {
      setState(() => _currentStep = 2);
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() => _isLoading = true);
    bool isValid = await AuthService.verifyOTP(_otpController.text);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (isValid) {
      setState(() => _currentStep = 3);
    } else {
      SnackbarHelper.showError(context, 'Mã OTP không chính xác');
    }
  }

  void _resetPassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ thông tin mật khẩu');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      SnackbarHelper.showError(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Giả lập call API đổi pass
    setState(() => _isLoading = false);

    if (!mounted) return;

    SnackbarHelper.showSuccess(context, 'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.');
    Navigator.pop(context); // Quay về màn hình Đăng nhập
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Quên mật khẩu', style: TextStyle(color: Colors.black87)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Khôi phục tài khoản', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Vui lòng nhập email của bạn. Chúng tôi sẽ gửi một mã OTP gồm 6 chữ số để xác thực.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email của bạn',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),
          _buildButton('Gửi mã OTP', _sendOtp),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập mã xác thực', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Mã OTP đã được gửi đến ${_emailController.text}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),
          _buildButton('Xác nhận OTP', _verifyOtp),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tạo mật khẩu mới', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Mật khẩu mới của bạn phải khác mật khẩu đã sử dụng trước đó.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 32),
          _buildButton('Đổi mật khẩu', _resetPassword),
        ],
      );
    }
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
