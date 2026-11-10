import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/registration_otp_service.dart';
import 'profile_setup_screen.dart';
import 'widgets/account_form_layout.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  String? _notice;
  DateTime? _retryAt;

  int get _secondsRemaining {
    final expiry = AuthService.registrationChallenge?.expiresAt;
    if (expiry == null) return 0;
    return ((expiry.difference(DateTime.now()).inMilliseconds / 1000).ceil())
        .clamp(0, 300);
  }

  int get _resendSeconds {
    final now = DateTime.now();
    final delay = AuthService.registrationChallenge?.resendSeconds(now) ?? 0;
    final retry = _retryAt == null
        ? 0
        : ((_retryAt!.difference(now).inMilliseconds / 1000).ceil()).clamp(
            0,
            3600,
          );
    return delay > retry ? delay : retry;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onResendOtp() async {
    if (_isLoading || _isResending || _resendSeconds > 0) return;
    setState(() {
      _isResending = true;
      _error = null;
      _notice = null;
    });
    try {
      await AuthService.resendRegistrationOtp();
      if (!mounted) return;
      _otpController.clear();
      setState(() {
        _retryAt = null;
        _notice = 'Mã xác minh mới đã được gửi đến email của bạn.';
      });
    } on OtpRequestException catch (error) {
      if (mounted)
        setState(() {
          _error = error.message;
          _retryAt = DateTime.now().add(Duration(seconds: error.retryAfter));
        });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _onVerifyPressed() async {
    if (_isLoading || _isResending) return;
    final code = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Vui lòng nhập đúng 6 chữ số OTP.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _notice = null;
    });
    final result = await AuthService.verifyRegistrationOtp(code);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const ProfileSetupScreen()),
      );
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _secondsRemaining;
    final resend = _resendSeconds;
    final email = AuthService.registrationChallenge?.email ?? '';
    final time =
        (seconds ~/ 60).toString() +
        ':' +
        (seconds % 60).toString().padLeft(2, '0');
    return AccountFormLayout(
      title: 'XÁC MINH EMAIL',
      subtitle: 'Nhập mã 6 chữ số đã gửi đến\n$email',
      children: [
        TextField(
          controller: _otpController,
          enabled: !_isLoading && !_isResending,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          autofillHints: const [AutofillHints.oneTimeCode],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onVerifyPressed(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 10),
          decoration: AccountFormLayout.input('Mã OTP'),
        ),
        const SizedBox(height: 18),
        Text(
          seconds == 0
              ? 'Mã xác minh đã hết hạn.'
              : 'Mã có hiệu lực trong $time',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF999999)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 16),
          Text(_notice!, style: const TextStyle(color: Colors.green)),
        ],
        const SizedBox(height: 26),
        ElevatedButton(
          onPressed: _isLoading || _isResending || seconds == 0
              ? null
              : _onVerifyPressed,
          style: AccountFormLayout.buttonStyle,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('XÁC NHẬN'),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _isLoading || _isResending || resend > 0
              ? null
              : _onResendOtp,
          child: Text(
            _isResending
                ? 'Đang gửi mã…'
                : resend > 0
                ? 'Gửi lại mã sau ' + resend.toString() + 's'
                : 'Gửi lại mã xác minh',
            style: TextStyle(
              color: resend > 0 ? Colors.grey : AccountFormLayout.linkColor,
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading || _isResending
              ? null
              : () => Navigator.pop(context),
          child: const Text(
            'Thay đổi email',
            style: TextStyle(color: AccountFormLayout.linkColor),
          ),
        ),
      ],
    );
  }
}
