// Author: Chih An (GitHub: ChangChinAn)
// UC03: Nhập mật khẩu và thông tin cá nhân để tạo tài khoản email.
import 'package:flutter/material.dart';
import '../../services/otp_verification_service.dart';
import '../../services/registration_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.verification,
    this.service, this.onVerificationExpired});
  final OtpVerificationResult verification;
  final RegistrationService? service;
  final VoidCallback? onVerificationExpired;
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final RegistrationService _service;
  bool _busy = false;
  bool _hidePassword = true;
  bool _proofInvalid = false;
  String? _error;
  RegisteredCustomer? _customer;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RegistrationService();
  }

  Future<void> _register() async {
    if (_busy || _proofInvalid || !_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final customer = await _service.register(verificationToken: widget.verification.verificationToken,
        name: _name.text, phone: _phone.text, password: _password.text);
      if (!mounted) return;
      setState(() => _customer = customer);
      _password.clear(); _confirmPassword.clear();
    } on RegistrationException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; _proofInvalid = error.needsNewVerification; });
      if (_proofInvalid) widget.onVerificationExpired?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _password.dispose(); _confirmPassword.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tạo tài khoản')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: _customer != null ? Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Tạo tài khoản thành công. Chào ${_customer!.name}!'),
          const SizedBox(height: 12), Text(_customer!.email),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => Navigator.pop(context, _customer), child: const Text('Hoàn tất')),
        ]) : Form(key: _formKey, child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(initialValue: widget.verification.email, readOnly: true,
              decoration: const InputDecoration(labelText: 'Email đã xác minh')),
            const SizedBox(height: 16),
            TextFormField(controller: _name, enabled: !_busy && !_proofInvalid, maxLength: 100,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (value) => value == null || value.trim().isEmpty || value.trim().length > 100
                ? 'Vui lòng nhập họ tên từ 1 đến 100 ký tự.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, enabled: !_busy && !_proofInvalid,
              keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: (value) => RegExp(r'^0\d{9}$').hasMatch(value?.trim() ?? '')
                ? null : 'Số điện thoại gồm 10 số, bắt đầu bằng 0.'),
            const SizedBox(height: 16),
            TextFormField(controller: _password, enabled: !_busy && !_proofInvalid,
              obscureText: _hidePassword, autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(labelText: 'Mật khẩu', errorMaxLines: 4,
                suffixIcon: IconButton(onPressed: _busy ? null : () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off))),
              validator: (value) => RegistrationValidation.passwordError(value ?? '')),
            const SizedBox(height: 8),
            const Text('Tối thiểu 12 ký tự không dấu; gồm chữ hoa, chữ thường, số và ký tự đặc biệt.'),
            const SizedBox(height: 16),
            TextFormField(controller: _confirmPassword, enabled: !_busy && !_proofInvalid,
              obscureText: _hidePassword,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
              validator: (value) => value == _password.text ? null : 'Mật khẩu xác nhận không khớp.'),
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy || _proofInvalid ? null : _register,
              child: Text(_busy ? 'Đang tạo tài khoản...' : 'Tạo tài khoản')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_proofInvalid)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại để xác minh email mới')),
          ],
        )),
      ),
    ))),
  );
}
