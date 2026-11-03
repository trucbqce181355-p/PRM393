// Author: Chih An (GitHub: ChangChinAn)
// UC05–UC08: Đăng nhập, liên kết Google và điều hướng hoàn tất hồ sơ lần đầu.
import 'package:flutter/material.dart';
import '../../services/login_service.dart';
import '../../services/google_auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'link_google_screen.dart';
import 'google_profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.service, this.googleService});
  final LoginService? service;
  final GoogleAuthService? googleService;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final LoginService _service;
  late final GoogleAuthService _googleService;
  bool _busy = false;
  bool _googleBusy = false;
  bool get _isBusy => _busy || _googleBusy;
  bool _hidePassword = true;
  String? _error;
  String? _info;
  LoginResult? _result;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LoginService();
    _googleService = widget.googleService ?? GoogleAuthService(loginService: _service);
  }

  Future<void> _login() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; _info = null; });
    try {
      final result = await _service.login(_email.text, _password.text);
      if (!mounted) return;
      setState(() => _result = result);
      _password.clear();
    } on LoginException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleLogin() async {
    if (_isBusy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _googleBusy = true; _error = null;
      _info = 'Hoàn tất đăng nhập Google trong trình duyệt rồi quay lại ứng dụng.';
    });
    try {
      final result = await _googleService.signIn();
      if (!mounted) return;
      setState(() { _result = result; _info = null; });
      _password.clear();
    } on LoginException catch (error) {
      if (!mounted) return;
      if (error.code == 'account_link_required' && _googleService.requiresAccountLink) {
        final linked = await Navigator.push<LoginResult>(context,
          MaterialPageRoute(builder: (_) => LinkGoogleScreen(service: _googleService)));
        _googleService.clearPendingLink();
        if (!mounted) return;
        if (linked != null) {
          _password.clear();
          setState(() { _result = linked; _error = null; _info = null; });
        } else {
          setState(() { _error = null; _info = 'Đã hủy liên kết Google.'; });
        }
      } else {
        setState(() { _error = error.message; _info = null; });
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final reset = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
    if (!mounted || reset != true) return;
    _password.clear();
    setState(() { _error = null; _info = 'Mật khẩu đã được cập nhật. Vui lòng đăng nhập bằng mật khẩu mới.'; });
  }

  @override
  void dispose() {
    _email.dispose(); _password.dispose();
    if (widget.googleService == null) _googleService.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _result;
    if (session != null && session.customer.sessionProvider == 'google' && !session.customer.profileCompleted) {
      return GoogleProfileSetupScreen(session: session, service: _service,
        onCompleted: (result) => setState(() => _result = result),
        onRestart: () => setState(() { _result = null; _error = null; _info = null; }));
    }
    return Scaffold(
    appBar: AppBar(title: const Text('Đăng nhập')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: _result != null ? Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 56),
          const SizedBox(height: 16),
          const Text('Đăng nhập thành công.'),
          if (_result!.linkedExistingAccount)
            const Text('Google đã được liên kết với tài khoản email hiện có.'),
          Text('Xin chào ${_result!.customer.name.isNotEmpty ? _result!.customer.name : _result!.customer.email}!'),
          Text(_result!.customer.email),
          Text(_result!.customer.role == 'admin' ? 'Tài khoản quản trị viên' : 'Tài khoản khách hàng'),
        ]) : AutofillGroup(child: Form(key: _formKey, child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đăng nhập tài khoản', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            TextFormField(controller: _email, enabled: !_isBusy,
              keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => (value?.trim().length ?? 0) <= 254 &&
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
                  ? null : 'Vui lòng nhập email hợp lệ.'),
            const SizedBox(height: 16),
            TextFormField(controller: _password, enabled: !_isBusy, obscureText: _hidePassword,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(labelText: 'Mật khẩu',
                suffixIcon: IconButton(onPressed: _isBusy ? null : () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off))),
              validator: (value) => value == null || value.isEmpty || value.length > 256
                ? 'Vui lòng nhập mật khẩu hợp lệ.' : null),
            const SizedBox(height: 24),
            FilledButton(onPressed: _isBusy ? null : _login,
              child: Text(_busy ? 'Đang đăng nhập...' : 'Đăng nhập')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _isBusy ? null : _googleLogin,
              icon: const Icon(Icons.account_circle_outlined),
              label: Text(_googleBusy ? 'Đang đăng nhập Google...' : 'Đăng nhập bằng Google')),
            if (_googleBusy)
              TextButton(onPressed: _googleService.cancel, child: const Text('Hủy đăng nhập Google')),
            TextButton(onPressed: _isBusy ? null : _forgotPassword, child: const Text('Quên mật khẩu?')),
            TextButton(onPressed: _isBusy ? null : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Chưa có tài khoản? Đăng ký')),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_info != null) Text(_info!),
          ],
        ))),
      ),
    ))),
  );
  }
}
