// Author: Chih An (GitHub: ChangChinAn)
// UC13: Form thêm và chỉnh sửa địa chỉ giao hàng.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/delivery_address.dart';
import '../../services/login_service.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, required this.session, required this.service, this.address});
  final LoginResult session;
  final LoginService service;
  final DeliveryAddress? address;
  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  StreamSubscription<LoginResult?>? _subscription;
  bool _busy = false;
  bool _invalid = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.address?.title ?? '');
    _address = TextEditingController(text: widget.address?.address ?? '');
    _phone = TextEditingController(text: widget.address?.phone ?? widget.session.customer.phone);
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || session?.token == widget.session.token) return;
      setState(() { _invalid = true; _error = 'Phiên đã hết hạn. Vui lòng đăng nhập lại.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
  }
  Future<void> _save() async {
    if (_busy || _invalid || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      await widget.service.saveAddress(widget.session, id: widget.address?.id,
        title: _title.text, address: _address.text, phone: _phone.text);
      if (mounted && !_invalid) Navigator.pop(context, true);
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _title.dispose(); _address.dispose(); _phone.dispose(); super.dispose();
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: Scaffold(
    appBar: AppBar(title: Text(widget.address == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ')),
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
        child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(controller: _title, enabled: !_busy && !_invalid,
              decoration: const InputDecoration(labelText: 'Tên địa chỉ (Nhà riêng, Công ty...)'),
              validator: (value) => value == null || value.trim().isEmpty || value.trim().length > 100
                ? 'Tên địa chỉ từ 1 đến 100 ký tự.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _address, enabled: !_busy && !_invalid, minLines: 2, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết nhận hàng'),
              validator: (value) => value == null || value.trim().isEmpty || value.trim().length > 500
                ? 'Địa chỉ từ 1 đến 500 ký tự.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, enabled: !_busy && !_invalid, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại nhận hàng'),
              validator: (value) => RegExp(r'^0\d{9}$').hasMatch(value?.trim() ?? '')
                ? null : 'Số điện thoại gồm 10 số, bắt đầu bằng 0.'),
            const SizedBox(height: 24),
            FilledButton(onPressed: _busy || _invalid ? null : _save,
              child: Text(_busy ? 'Đang lưu...' : 'Lưu địa chỉ')),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text(_invalid ? 'Quay lại đăng nhập' : 'Hủy')),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ])),
      ),
    ))),
  ));
}
