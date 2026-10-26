import 'dart:async';
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
  bool _isResending = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Timer? _countdownTimer;
  int _secondsRemaining = AuthService.otpDurationSeconds;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final createdAt = AuthService.otpCreatedAt;
    if (createdAt != null) {
      final elapsed = DateTime.now().difference(createdAt).inSeconds;
      _secondsRemaining = (AuthService.otpDurationSeconds - elapsed).clamp(0, AuthService.otpDurationSeconds);
    } else {
      _secondsRemaining = AuthService.otpDurationSeconds;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      SnackbarHelper.showError(context, 'Vui lòng nhập Email hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    String error = await AuthService.loginWithEmail(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error.isNotEmpty) {
      SnackbarHelper.showError(context, error);
      return;
    } else {
      SnackbarHelper.showSuccess(context, 'Đã gửi mã OTP đến email của bạn');
    }

    _startCountdown();
    setState(() => _currentStep = 2);
  }

  void _onResendOtp() async {
    setState(() => _isResending = true);
    final error = await AuthService.resendOTP();
    setState(() => _isResending = false);

    if (!mounted) return;

    if (error.isEmpty) {
      SnackbarHelper.showSuccess(context, 'Đã gửi lại mã OTP mới!');
      _startCountdown();
    } else {
      SnackbarHelper.showError(context, 'Lỗi gửi lại OTP: $error (Bạn có thể dùng mã test 123456)');
      _startCountdown();
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyOTP(otp);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isValid) {
      SnackbarHelper.showSuccess(context, 'Xác minh OTP thành công!');
      _countdownTimer?.cancel();
      setState(() => _currentStep = 3);
    } else {
      SnackbarHelper.showError(context, result.message);
    }
  }

  void _resetPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ thông tin mật khẩu');
      return;
    }

    if (newPass.length < 6) {
      SnackbarHelper.showError(context, 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (newPass != confirmPass) {
      SnackbarHelper.showError(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    bool success;
    try {
      success = await DataService.resetPasswordByEmail(email, newPass);
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, error is StateError ? error.message : 'Không thể đặt lại mật khẩu.');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(
        context,
        'Đổi mật khẩu thành công! Vui lòng đăng nhập với mật khẩu mới.',
      );
      Navigator.pop(context); // Quay về màn hình Đăng nhập
    } else {
      SnackbarHelper.showError(context, 'Không tìm thấy tài khoản để cập nhật mật khẩu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
          const Text(
            'Khôi phục tài khoản',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng nhập email của bạn. Chúng tôi sẽ gửi một mã OTP gồm 6 chữ số để xác thực.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildButton('Gửi mã OTP', _sendOtp),
        ],
      );
    } else if (_currentStep == 2) {
      final isExpired = _secondsRemaining <= 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập mã xác thực',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã OTP đã được gửi đến ${_emailController.text}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Countdown Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExpired ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                    size: 18,
                    color: isExpired ? Colors.red : Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpired ? 'Mã OTP đã hết hạn' : 'Hiệu lực: ${_formatTime(_secondsRemaining)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isExpired ? Colors.red : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              letterSpacing: 10,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildButton('Xác nhận OTP', _verifyOtp),
          const SizedBox(height: 16),

          // Resend OTP Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Chưa nhận được mã? ', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: _isResending ? null : _onResendOtp,
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      )
                    : const Text(
                        'Gửi lại OTP',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tạo mật khẩu mới',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mật khẩu mới của bạn phải có ít nhất 6 ký tự.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
