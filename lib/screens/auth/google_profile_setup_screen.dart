// Author: Chih An (GitHub: ChangChinAn)
// UC08: Hoàn tất thông tin cá nhân sau khi đăng nhập Google lần đầu.
import 'package:flutter/material.dart';
import '../../services/login_service.dart';
import '../../services/registration_service.dart';

class GoogleProfileSetupScreen extends StatefulWidget {
  const GoogleProfileSetupScreen({super.key, required this.session, required this.service,
    required this.onCompleted, required this.onRestart});
  final LoginResult session;
  final LoginService service;
  final ValueChanged<LoginResult> onCompleted;
  final VoidCallback onRestart;
  @override
  State<GoogleProfileSetupScreen> createState() => _GoogleProfileSetupScreenState();
}

class _GoogleProfileSetupScreenState extends State<GoogleProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  bool _restartRequired = false;
  String? _error;
  bool get _needsPassword => !widget.session.customer.hasPassword;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.customer.name);
    _phone = TextEditingController(text: widget.session.customer.phone);
  }

  Future<void> _save() async {
    if (_busy || _restartRequired || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      final result = await widget.service.completeGoogleProfile(widget.session,
        name: _name.text, phone: _phone.text, password: _needsPassword ? _password.text : null);
      if (!mounted) return;
      _password.clear(); _confirm.clear();
      widget.onCompleted(result);
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _restartRequired = ['session_expired', 'account_unavailable', 'account_changed',
          'profile_completed', 'password_exists'].contains(error.code);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _password.dispose(); _confirm.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(canPop: false, child: Scaffold(
    appBar: AppBar(title: const Text('Hoàn tất hồ sơ Google'), automaticallyImplyLeading: false),
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Bổ sung thông tin để hoàn tất tài khoản của bạn.'),
            const SizedBox(height: 16),
            TextFormField(initialValue: widget.session.customer.email, readOnly: true,
              decoration: const InputDecoration(labelText: 'Email Google')),
            const SizedBox(height: 16),
            TextFormField(controller: _name, enabled: !_busy && !_restartRequired,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (value) => value == null || value.trim().isEmpty || value.trim().length > 100
                ? 'Nhập họ tên từ 1 đến 100 ký tự.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, enabled: !_busy && !_restartRequired,
              keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: (value) => RegExp(r'^0\d{9}$').hasMatch(value?.trim() ?? '')
                ? null : 'Số điện thoại gồm 10 số, bắt đầu bằng 0.'),
            if (_needsPassword) ...[
              const SizedBox(height: 16),
              TextFormField(controller: _password, enabled: !_busy && !_restartRequired,
                obscureText: _hidePassword, autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: 'Tạo mật khẩu tài khoản', errorMaxLines: 4,
                  suffixIcon: IconButton(onPressed: _busy ? null : () => setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off))),
                validator: (value) => RegistrationValidation.passwordError(value ?? '')),
              const SizedBox(height: 8),
              const Text('Mật khẩu cho phép bạn đăng nhập bằng email: từ 12 ký tự không dấu, có chữ hoa, chữ thường, số và ký tự đặc biệt.'),
              const SizedBox(height: 16),
              TextFormField(controller: _confirm, enabled: !_busy && !_restartRequired,
                obscureText: _hidePassword, decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                validator: (value) => value == _password.text ? null : 'Mật khẩu xác nhận không khớp.'),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy || _restartRequired ? null : _save,
              child: Text(_busy ? 'Đang lưu...' : 'Hoàn tất hồ sơ')),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_restartRequired)
              TextButton(onPressed: widget.onRestart, child: const Text('Đăng nhập lại')),
          ])),
      ),
    ))),
  ));
}
