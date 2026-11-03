// Author: Chih An (GitHub: ChangChinAn)
// UC01: Nhập email, yêu cầu OTP và gửi lại sau thời gian chờ.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/otp_request_service.dart';
import '../../services/otp_verification_service.dart';
import '../../services/registration_service.dart';
import 'otp_screen.dart';
import 'profile_setup_screen.dart';
import 'forgot_password_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.service, this.clock});
  final OtpRequestService? service;
  final DateTime Function()? clock;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final OtpRequestService _service;
  Timer? _timer;
  bool _sending = false;
  String? _message;
  bool _error = false;
  String? _cooldownEmail;
  DateTime? _resendAt;
  OtpEmailChallenge? _challenge;
  OtpVerificationResult? _verified;
  RegisteredCustomer? _createdCustomer;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  String get _normalizedEmail => _email.text.trim().toLowerCase();
  int get _remaining {
    if (_cooldownEmail != _normalizedEmail || _resendAt == null) return 0;
    return ((_resendAt!.difference(_now).inMilliseconds + 999) ~/ 1000).clamp(
      0,
      60,
    );
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? OtpRequestService();
  }

  void _startCooldown(String email, int seconds) {
    _cooldownEmail = email;
    _resendAt = _now.add(Duration(seconds: seconds));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (!_resendAt!.isAfter(_now)) timer.cancel();
    });
  }

  Future<void> _requestOtp() async {
    if (_sending || _remaining > 0 || !_formKey.currentState!.validate()) {
      return;
    }
    final email = _normalizedEmail;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      final challenge = await _service.request(email);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _verified = null;
        _createdCustomer = null;
        _error = false;
        _message =
            'Đã gửi mã OTP đến ${challenge.email}. Vui lòng kiểm tra hộp thư.';
        _startCooldown(challenge.email, challenge.resendAfter);
      });
    } on OtpRequestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _message = error.message;
        if (error.retryAfter > 0) _startCooldown(email, error.retryAfter);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openVerification() async {
    final challenge = _challenge;
    if (challenge == null) return;
    final result = await Navigator.push<OtpVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(challenge: challenge, clock: widget.clock),
      ),
    );
    if (!mounted || result == null || _challenge?.id != challenge.id) return;
    setState(() {
      _verified = result;
      _message = 'Email ${result.email} đã được xác minh.';
    });
    await _openProfile();
  }

  Future<void> _openProfile() async {
    final verification = _verified;
    if (verification == null || _createdCustomer != null) return;
    final customer = await Navigator.push<RegisteredCustomer>(context,
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(verification: verification,
        onVerificationExpired: () {
          if (!mounted) return;
          setState(() {
            _verified = null; _challenge = null;
            _message = 'Vui lòng gửi mã mới và xác minh lại email.';
          });
        })));
    if (!mounted || customer == null) return;
    setState(() {
      _createdCustomer = customer;
      _message = 'Tạo tài khoản thành công cho ${customer.email}.';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác minh email')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nhận mã xác minh email',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nhập email để nhận mã OTP gồm 6 chữ số. Nếu chưa nhận được, bạn có thể gửi lại sau thời gian chờ.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    enabled: !_sending,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Vui lòng nhập email hợp lệ.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _sending || _remaining > 0 ? null : _requestOtp,
                    child: Text(
                      _sending
                          ? 'Đang gửi...'
                          : _remaining > 0
                          ? 'Gửi lại sau $_remaining giây'
                          : _challenge?.email == _normalizedEmail
                          ? 'Gửi lại mã OTP'
                          : 'Nhận mã OTP',
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _error
                            ? Theme.of(context).colorScheme.error
                            : Colors.green.shade800,
                      ),
                    ),
                  ],
                  if (_challenge?.email == _normalizedEmail)
                    TextButton(
                      onPressed: _sending || _verified != null
                          ? null
                          : _openVerification,
                      child: Text(
                        _verified == null
                            ? 'Nhập mã xác minh'
                            : 'Email đã được xác minh',
                      ),
                    ),
                  if (_verified != null && _verified!.email == _normalizedEmail)
                    TextButton(onPressed: _createdCustomer == null ? _openProfile : null,
                      child: Text(_createdCustomer == null ? 'Hoàn tất thông tin tài khoản' : 'Tài khoản đã được tạo')),
                  TextButton(onPressed: _sending ? null : () async {
                    final reset = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    if (mounted && reset == true) setState(() {
                      _error = false; _message = 'Mật khẩu đã được đặt lại thành công.';
                    });
                  }, child: const Text('Quên mật khẩu?')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
