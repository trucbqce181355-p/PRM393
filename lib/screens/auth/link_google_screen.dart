// Author: Chih An (GitHub: ChangChinAn)
// UC07: Xác nhận mật khẩu tài khoản email cũ trước khi liên kết Google.
import 'package:flutter/material.dart';
import '../../services/google_auth_service.dart';
import '../../services/login_service.dart';
import 'forgot_password_screen.dart';

class LinkGoogleScreen extends StatefulWidget {
  const LinkGoogleScreen({super.key, required this.service});
  final GoogleAuthService service;
  @override
  State<LinkGoogleScreen> createState() => _LinkGoogleScreenState();
}

class _LinkGoogleScreenState extends State<LinkGoogleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  bool _restartRequired = false;
  String? _error;
  String? _info;

  Future<void> _link() async {
    if (_busy || _restartRequired || !_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; _info = null; });
    try {
      final result = await widget.service.linkExistingAccount(_password.text);
      if (!mounted) return;
      _password.clear();
      Navigator.pop(context, result);
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _restartRequired = !widget.service.requiresAccountLink ||
          ['google_session_changed', 'invalid_account', 'google_link_denied', 'google_already_linked'].contains(error.code);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final reset = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
    if (!mounted || reset != true) return;
    _password.clear();
    setState(() { _error = null; _info = 'Nhập mật khẩu mới của tài khoản email để xác nhận liên kết.'; });
  }

  @override
  void dispose() { _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Liên kết Google')),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
          child: Form(key: _formKey, child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Email Google đã trùng với một tài khoản hiện có. Xác nhận mật khẩu tài khoản email để liên kết và tiếp tục dùng dữ liệu cũ.'),
              const SizedBox(height: 20),
              TextFormField(initialValue: widget.service.pendingLinkEmail ?? '', readOnly: true,
                decoration: const InputDecoration(labelText: 'Email tài khoản Google')),
              const SizedBox(height: 16),
              TextFormField(controller: _password, enabled: !_busy && !_restartRequired,
                obscureText: _hidePassword, autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(labelText: 'Mật khẩu tài khoản email',
                  suffixIcon: IconButton(onPressed: _busy ? null : () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off))),
                validator: (value) => value == null || value.isEmpty || value.length > 256
                  ? 'Vui lòng nhập mật khẩu tài khoản email.' : null),
              const SizedBox(height: 24),
              FilledButton(onPressed: _busy || _restartRequired ? null : _link,
                child: Text(_busy ? 'Đang liên kết...' : 'Xác nhận liên kết Google')),
              TextButton(onPressed: _busy ? null : _forgotPassword, child: const Text('Quên mật khẩu tài khoản email?')),
              TextButton(onPressed: _busy ? null : () => Navigator.pop(context),
                child: Text(_restartRequired ? 'Quay lại đăng nhập' : 'Hủy liên kết')),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_info != null) Text(_info!),
            ],
          )),
        ),
      ))),
    ),
  );
}
