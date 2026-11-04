import 'dart:async';
import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';
import '../../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  Timer? _countdownTimer;
  int _secondsRemaining = AuthService.otpDurationSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onResendOtp() async {
    setState(() => _isResending = true);
    final error = await AuthService.resendOTP();
    setState(() => _isResending = false);

    if (!mounted) return;

    if (error.isEmpty) {
      SnackbarHelper.showSuccess(context, 'Đã gửi lại mã OTP mới đến email của bạn!');
      _startCountdown();
    } else {
      SnackbarHelper.showError(context, 'Lỗi gửi lại OTP: $error (Bạn có thể dùng mã test 123456)');
      _startCountdown();
    }
  }

  void _onVerifyPressed() async {
    final otpText = _otpController.text.trim();
    if (otpText.length < 6) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyOTP(otpText);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isValid) {
      SnackbarHelper.showSuccess(context, 'Xác minh OTP thành công!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    } else {
      SnackbarHelper.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetEmail = AuthService.pendingEmail ?? 'email của bạn';
    final isExpired = _secondsRemaining <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xác thực Email',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chúng tôi đã gửi mã xác thực 6 số đến địa chỉ:\n$targetEmail',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

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
              const SizedBox(height: 32),

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

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onVerifyPressed,
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
                      : const Text(
                          'Xác nhận OTP',
                          style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP Action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn chưa nhận được mã? ', style: TextStyle(color: Colors.grey)),
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
          ),
        ),
      ),
    );
  }
}
