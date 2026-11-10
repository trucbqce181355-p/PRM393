import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/registration_otp_service.dart';
import 'otp_screen.dart';
import 'widgets/account_form_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.restoreRegistrationOtp();
      final email = _emailController.text.trim().toLowerCase();
      final current = AuthService.registrationChallenge;
      if (current == null ||
          current.email != email ||
          !current.expiresAt.isAfter(DateTime.now())) {
        await AuthService.requestRegistrationOtp(email);
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const OtpScreen()),
      );
    } on OtpRequestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AccountFormLayout(
    title: 'TẠO TÀI KHOẢN',
    subtitle: 'Nhập email để nhận mã xác minh tài khoản.',
    children: [
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onRegisterPressed(),
          decoration: AccountFormLayout.input('Email'),
          validator: (value) {
            final email = value?.trim() ?? '';
            return email.length <= 254 &&
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                ? null
                : 'Vui lòng nhập địa chỉ email hợp lệ.';
          },
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Mã xác minh có hiệu lực 5 phút. Bạn có thể yêu cầu gửi lại sau 60 giây.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF999999), height: 1.6),
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _isLoading ? null : _onRegisterPressed,
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
            : const Text('GỬI MÃ XÁC MINH'),
      ),
      const SizedBox(height: 22),
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text(
          'Đã có tài khoản? Đăng nhập',
          style: TextStyle(color: AccountFormLayout.linkColor),
        ),
      ),
    ],
  );
}
