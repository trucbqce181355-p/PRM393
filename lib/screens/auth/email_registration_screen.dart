import 'package:flutter/material.dart';

import '../../utils/account_password_validator.dart';

import '../../services/email_otp_service.dart';
import '../../utils/snackbar_helper.dart';
import 'login_screen.dart';

class EmailRegistrationScreen extends StatefulWidget {
  const EmailRegistrationScreen({super.key});
  @override
  State<EmailRegistrationScreen> createState() =>
      _EmailRegistrationScreenState();
}

class _EmailRegistrationScreenState extends State<EmailRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final String _email;
  bool _saving = false;
  bool _obscure = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _email = EmailOtpService.verifiedEmail ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_saving || _completed || !_formKey.currentState!.validate()) return;
    if (_email.isEmpty || EmailOtpService.registrationToken == null) {
      SnackbarHelper.showError(
        context,
        'Vui lòng xác minh email trước khi đăng ký.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await EmailOtpService.register(
        name: _name.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      _password.clear();
      _confirm.clear();
      setState(() => _completed = true);
      SnackbarHelper.showSuccess(context, 'Tạo tài khoản thành công!');
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          error is StateError
              ? error.message
              : 'Không thể tạo tài khoản. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openLogin() => Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hoàn tất đăng ký')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _completed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text('Tạo tài khoản thành công!'),
                    Text(_email),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _openLogin,
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: _email,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email đã xác minh',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                        ),
                        validator: (value) =>
                            value == null ||
                                value.trim().isEmpty ||
                                value.trim().length > 100
                            ? 'Nhập họ tên từ 1 đến 100 ký tự.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phone,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                        ),
                        validator: (value) =>
                            RegExp(r'^0\d{9}$').hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Số điện thoại gồm 10 số, bắt đầu bằng 0.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_saving,
                        obscureText: _obscure,
                        validator: validateAccountPassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          suffixIcon: IconButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirm,
                        enabled: !_saving,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Nhập lại mật khẩu',
                        ),
                        validator: (value) =>
                            value == _password.text &&
                                (value?.isNotEmpty ?? false)
                            ? null
                            : 'Mật khẩu nhập lại không khớp.',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _register,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Tạo tài khoản'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
}
