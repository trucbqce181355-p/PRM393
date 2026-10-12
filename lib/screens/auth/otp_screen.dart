import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import 'profile_setup_screen.dart';

/// Bước 3: Xác minh mã OTP
class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ 6 chữ số OTP');
      return;
    }

    setState(() => _isLoading = true);
    final isValid = await AuthService.verifyOtp(otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      SnackbarHelper.showSuccess(context, 'Xác minh OTP thành công!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(
            phone: widget.phone,
            authMethod: 'phone',
          ),
        ),
      );
    } else {
      SnackbarHelper.showError(
        context,
        'Mã OTP không chính xác. Bạn có thể sử dụng mã test: 123456',
      );
    }
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0) return;

    try {
      final newOtp = await AuthService.sendPhoneOtp(widget.phone);
      if (!mounted) return;
      _startCountdown();
      SnackbarHelper.showSuccess(
        context,
        'Đã gửi lại mã OTP! Mã thử nghiệm: $newOtp (hoặc 123456)',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Gửi lại OTP thất bại: $e');
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
          'Xác minh tài khoản',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhập mã xác minh OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  children: [
                    const TextSpan(text: 'Mã xác thực 6 số đã được gửi đến số điện thoại\n'),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Gợi ý mã test
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Gợi ý mã kiểm thử: 123456',
                      style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Ô nhập OTP
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 16,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: const TextStyle(letterSpacing: 16, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF7F9F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Nút xác nhận OTP
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Xác minh OTP',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Gửi lại OTP & Đếm ngược
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa nhận được mã? ', style: TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: _secondsRemaining == 0 ? _handleResendOtp : null,
                    child: Text(
                      _secondsRemaining > 0 ? 'Gửi lại sau (${_secondsRemaining}s)' : 'Gửi lại mã OTP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining > 0 ? Colors.grey : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
