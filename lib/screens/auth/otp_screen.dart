import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/email_otp_service.dart';
import '../../utils/snackbar_helper.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email});
  final String email;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  Timer? _timer;
  int _remaining = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _remaining = EmailOtpService.resendAfter;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remaining > 0) _remaining--;
      });
      if (_remaining == 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_sending || _remaining > 0) return;
    setState(() => _sending = true);
    try {
      await EmailOtpService.sendOtp(widget.email);
      if (!mounted) return;
      setState(_startCountdown);
      SnackbarHelper.showSuccess(
        context,
        'Mã OTP mới đã được gửi tới email của bạn.',
      );
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          error is StateError
              ? error.message
              : 'Không thể gửi lại OTP. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('OTP email')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Mã OTP gồm 6 số đã được gửi tới ${widget.email}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra hộp thư và thư rác.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _sending || _remaining > 0 ? null : _resend,
              icon: const Icon(Icons.refresh),
              label: Text(
                _sending
                    ? 'Đang gửi...'
                    : _remaining > 0
                    ? 'Gửi lại OTP sau ${_remaining}s'
                    : 'Gửi lại OTP',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
