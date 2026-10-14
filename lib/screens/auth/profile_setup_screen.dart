import 'package:flutter/material.dart';

import '../../services/auth_api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/account_password_validator.dart';
import '../../utils/snackbar_helper.dart';
import '../user/user_home_screen.dart';
import 'login_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final String _email;
  late final bool _needsPassword;
  bool _saving = false;
  bool _leaving = false;
  bool _obscure = true;
  bool _sessionExpired = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _name.text = AuthService.currentUser?.name ?? '';
    _phone.text = AuthService.currentUser?.phone ?? '';
    _email = AuthService.currentUser?.email ?? '';
    _needsPassword = !AuthService.hasPassword;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_saving ||
        _leaving ||
        _completed ||
        _sessionExpired ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.completeAuthenticatedProfile(
        name: _name.text,
        phone: _phone.text,
        password: _needsPassword ? _password.text : null,
      );
      if (!mounted) return;
      _completed = true;
      _password.clear();
      _confirm.clear();
      SnackbarHelper.showSuccess(context, 'Hoàn tất hồ sơ thành công!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      if (error is BackendAuthException && error.status == 401) {
        _sessionExpired = true;
      }
      SnackbarHelper.showError(
        context,
        error is StateError
            ? error.message
            : 'Không thể lưu hồ sơ. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _returnToLogin() async {
    if (_saving || _leaving || _completed) return;
    setState(() => _leaving = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Không thể đăng xuất. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn tất hồ sơ'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bổ sung thông tin để bắt đầu sử dụng Fruitopia.'),
                  const SizedBox(height: 20),
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
                    enabled: !_saving && !_leaving,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
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
                    enabled: !_saving && !_leaving,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại liên hệ',
                    ),
                    validator: (value) =>
                        RegExp(r'^0\d{9}$').hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Số điện thoại gồm 10 số, bắt đầu bằng 0.',
                  ),
                  if (_needsPassword) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_saving && !_leaving,
                      obscureText: _obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      validator: validateAccountPassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu Fruitopia',
                        helperText: '12–256 ký tự: chữ hoa, chữ thường, số và ký tự đặc biệt.',
                        helperMaxLines: 2,
                        suffixIcon: IconButton(
                          onPressed: _saving || _leaving
                              ? null
                              : () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      enabled: !_saving && !_leaving,
                      obscureText: _obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                      ),
                      validator: (value) =>
                          value == _password.text &&
                              (value?.isNotEmpty ?? false)
                          ? null
                          : 'Mật khẩu nhập lại không khớp.',
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_sessionExpired)
                    const Text(
                      'Phiên đã hết hạn. Vui lòng quay lại đăng nhập.',
                    ),
                  ElevatedButton(
                    onPressed: _saving || _leaving || _sessionExpired
                        ? null
                        : _complete,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Hoàn tất hồ sơ'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _saving || _leaving ? null : _returnToLogin,
                    child: Text(
                      _leaving
                          ? 'Đang đăng xuất...'
                          : 'Đăng xuất và quay lại đăng nhập',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
