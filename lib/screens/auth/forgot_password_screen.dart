// Author: Chih An (GitHub: ChangChinAn)
// UC04: Nhập email → nhận/xác minh OTP → nhập và xác nhận mật khẩu mới.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/otp_request_service.dart';
import '../../services/otp_verification_service.dart';
import '../../services/password_reset_service.dart';
import '../../services/registration_service.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.otpService, this.resetService});
  final OtpRequestService? otpService;
  final PasswordResetService? resetService;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final OtpRequestService _otpService;
  late final PasswordResetService _resetService;
  OtpEmailChallenge? _challenge;
  OtpVerificationResult? _verification;
  Timer? _timer;
  DateTime? _resendAt;
  String? _cooldownEmail;
  String? _error;
  String? _info;
  bool _requesting = false;
  bool _verifying = false;
  bool _resetting = false;
  bool _done = false;
  bool _hidePassword = true;
  bool get _busy => _requesting || _verifying || _resetting;
  String get _normalizedEmail => _email.text.trim().toLowerCase();
  int get _remaining {
    if (_resendAt == null || _cooldownEmail != _normalizedEmail) return 0;
    return ((_resendAt!.difference(DateTime.now()).inMilliseconds + 999) ~/ 1000).clamp(0, 86400);
  }

  @override
  void initState() {
    super.initState();
    _otpService = widget.otpService ?? OtpRequestService();
    _resetService = widget.resetService ?? PasswordResetService();
  }

  void _cooldown(String email, int seconds) {
    _cooldownEmail = email;
    _resendAt = DateTime.now().add(Duration(seconds: seconds));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {});
      if (!_resendAt!.isAfter(DateTime.now())) timer.cancel();
    });
  }

  Future<void> _sendOtp() async {
    if (_busy || _remaining > 0 || !_emailForm.currentState!.validate()) return;
    final email = _normalizedEmail;
    bool sent = false;
    setState(() { _requesting = true; _error = null; _info = null; });
    try {
      final challenge = await _otpService.request(email, purpose: 'password_reset');
      if (!mounted) return;
      setState(() {
        _challenge = challenge; _verification = null;
        _info = 'Đã gửi mã đặt lại mật khẩu đến ${challenge.email}.';
        _cooldown(challenge.email, challenge.resendAfter);
      });
      sent = true;
    } on OtpRequestException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        if (error.retryAfter > 0) _cooldown(email, error.retryAfter);
      });
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    if (mounted && sent) await _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    final challenge = _challenge;
    if (_busy || challenge == null) return;
    setState(() => _verifying = true);
    try {
      final verification = await Navigator.push<OtpVerificationResult>(context,
        MaterialPageRoute(builder: (_) => OtpScreen(challenge: challenge)));
      if (!mounted || verification == null || _challenge?.id != challenge.id) return;
      if (verification.purpose != 'password_reset' || verification.email != challenge.email) {
        setState(() => _error = 'Xác minh không dành cho yêu cầu đặt lại mật khẩu này.');
        return;
      }
      setState(() { _verification = verification; _error = null; _info = null; });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resetPassword() async {
    final verification = _verification;
    if (_busy || verification == null || !_passwordForm.currentState!.validate()) return;
    setState(() { _resetting = true; _error = null; });
    try {
      await _resetService.reset(verificationToken: verification.verificationToken, password: _password.text);
      if (!mounted) return;
      setState(() { _done = true; _verification = null; _challenge = null; });
      _password.clear(); _confirmPassword.clear(); _timer?.cancel();
    } on PasswordResetException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        if (error.needsNewVerification) { _verification = null; _challenge = null; }
      });
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); _email.dispose(); _password.dispose(); _confirmPassword.dispose();
    if (widget.otpService == null) _otpService.dispose();
    if (widget.resetService == null) _resetService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quên mật khẩu')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_done) ...[
              const Text('Đặt lại mật khẩu thành công. Bạn có thể sử dụng mật khẩu mới để đăng nhập.'),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hoàn tất')),
            ] else if (_verification == null) Form(key: _emailForm, child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nhập email tài khoản để nhận mã OTP đặt lại mật khẩu.'),
                const SizedBox(height: 16),
                TextFormField(controller: _email, enabled: !_busy,
                  keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email tài khoản'),
                  validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
                    ? null : 'Vui lòng nhập email hợp lệ.',
                  onChanged: (_) => setState(() {
                    if (_challenge?.email != _normalizedEmail) _challenge = null;
                    _info = null; _error = null;
                  })),
                const SizedBox(height: 24),
                FilledButton(onPressed: _busy || _remaining > 0 ? null : _sendOtp,
                  child: Text(_requesting ? 'Đang gửi...' : _remaining > 0 ? 'Gửi lại sau $_remaining giây'
                    : _challenge == null ? 'Gửi mã đặt lại mật khẩu' : 'Gửi lại OTP')),
                if (_challenge != null)
                  TextButton(onPressed: _busy ? null : _verifyOtp, child: const Text('Nhập mã xác minh')),
              ],
            )) else Form(key: _passwordForm, child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tạo mật khẩu mới cho ${_verification!.email}'),
                const SizedBox(height: 16),
                TextFormField(controller: _password, enabled: !_busy, obscureText: _hidePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(labelText: 'Mật khẩu mới', errorMaxLines: 4,
                    suffixIcon: IconButton(onPressed: _busy ? null : () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off))),
                  validator: (value) => RegistrationValidation.passwordError(value ?? '')),
                const SizedBox(height: 8),
                const Text('Từ 12 đến 256 ký tự không dấu, có chữ hoa, chữ thường, số và ký tự đặc biệt.'),
                const SizedBox(height: 16),
                TextFormField(controller: _confirmPassword, enabled: !_busy, obscureText: _hidePassword,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                  validator: (value) => value == _password.text ? null : 'Mật khẩu xác nhận không khớp.'),
                const SizedBox(height: 24),
                FilledButton(onPressed: _busy ? null : _resetPassword,
                  child: Text(_resetting ? 'Đang đặt lại mật khẩu...' : 'Đặt lại mật khẩu')),
              ],
            )),
            if (_info != null) ...[const SizedBox(height: 12), Text(_info!)],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    ))),
  );
}
