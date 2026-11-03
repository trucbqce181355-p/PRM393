// Author: Chih An (GitHub: ChangChinAn)
// UC12: Chỉnh sửa họ tên/số điện thoại và lưu hồ sơ qua phiên đã xác thực.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/customer_profile.dart';
import '../../services/login_service.dart';

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key, required this.session, required this.service, required this.profile});
  final LoginResult session;
  final LoginService service;
  final CustomerProfile profile;
  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  StreamSubscription<LoginResult?>? _subscription;
  bool _busy = false;
  bool _sessionInvalid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(text: widget.profile.phone);
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || session?.token == widget.session.token) return;
      setState(() { _sessionInvalid = true; _error = 'Phiên đã hết hạn hoặc thay đổi. Vui lòng đăng nhập lại.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    if (_busy || _sessionInvalid || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      await widget.service.updateProfile(widget.session, name: _name.text, phone: _phone.text);
      if (!mounted || _sessionInvalid) return;
      Navigator.pop(context, true);
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; _sessionInvalid = error.code == 'session_expired'; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _name.dispose(); _phone.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: Scaffold(
    appBar: AppBar(title: const Text('Chỉnh sửa thông tin cá nhân')),
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(initialValue: widget.profile.email, readOnly: true,
              decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextFormField(controller: _name, enabled: !_busy && !_sessionInvalid,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: (value) => value == null || value.trim().isEmpty || value.trim().length > 100
                ? 'Nhập họ tên từ 1 đến 100 ký tự.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, enabled: !_busy && !_sessionInvalid,
              keyboardType: TextInputType.phone, autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: (value) => RegExp(r'^0\d{9}$').hasMatch(value?.trim() ?? '')
                ? null : 'Số điện thoại gồm 10 số, bắt đầu bằng 0.'),
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy || _sessionInvalid ? null : _save,
              child: Text(_busy ? 'Đang lưu...' : 'Lưu thay đổi')),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(_sessionInvalid ? 'Quay lại đăng nhập' : 'Hủy')),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ])),
      ),
    ))),
  ));
}
