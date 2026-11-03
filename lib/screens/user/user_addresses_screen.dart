// Author: Chih An (GitHub: ChangChinAn)
// UC13–UC14: Quản lý địa chỉ và chọn địa chỉ giao hàng mặc định.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/delivery_address.dart';
import '../../services/login_service.dart';
import 'address_form_screen.dart';

class UserAddressesScreen extends StatefulWidget {
  const UserAddressesScreen({super.key, required this.session, required this.service});
  final LoginResult session;
  final LoginService service;
  @override
  State<UserAddressesScreen> createState() => _UserAddressesScreenState();
}
class _UserAddressesScreenState extends State<UserAddressesScreen> with WidgetsBindingObserver {
  StreamSubscription<LoginResult?>? _subscription;
  List<DeliveryAddress> _addresses = [];
  bool _loading = false;
  bool _working = false;
  bool _invalid = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || session?.token == widget.session.token) return;
      setState(() { _addresses = []; _invalid = true; _error = 'Phiên đã hết hạn. Vui lòng đăng nhập lại.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
    unawaited(_load());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_working) unawaited(_load());
  }
  Future<void> _load() async {
    if (_loading || _working || _invalid) return;
    setState(() { _loading = true; _error = null; _addresses = []; });
    try {
      final addresses = await widget.service.fetchAddresses(widget.session);
      if (mounted && !_invalid) setState(() => _addresses = addresses);
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _edit([DeliveryAddress? address]) async {
    if (_working || _loading || _invalid) return;
    setState(() => _working = true);
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>
      AddressFormScreen(session: widget.session, service: widget.service, address: address)));
    if (!mounted) return;
    setState(() => _working = false);
    if (_invalid) { Navigator.pop(context); return; }
    if (saved == true) await _load();
  }
  Future<void> _delete(DeliveryAddress address) async {
    if (_working || _loading || _invalid) return;
    setState(() => _working = true);
    bool changed = false;
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa địa chỉ'), content: Text('Bạn có muốn xóa địa chỉ "${address.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xóa')),
        ]));
      if (!mounted || _invalid || confirmed != true) return;
      await widget.service.deleteAddress(widget.session, address.id);
      changed = true;
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _working = false); }
    if (mounted && changed && !_invalid) await _load();
  }
  Future<void> _setDefault(DeliveryAddress address) async {
    if (_working || _loading || _invalid || address.isDefault) return;
    setState(() { _working = true; _error = null; });
    bool changed = false;
    try {
      await widget.service.selectDefaultAddress(widget.session, address.id);
      changed = true;
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _working = false); }
    if (mounted && changed && !_invalid) await _load();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel()); super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Địa chỉ giao hàng'), actions: [
      IconButton(onPressed: _loading || _working || _invalid ? null : _load,
        tooltip: 'Tải lại địa chỉ', icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: FloatingActionButton(onPressed: _loading || _working || _invalid ? null : () => _edit(),
      tooltip: 'Thêm địa chỉ', child: const Icon(Icons.add)),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton(onPressed: _working ? null : _invalid ? () => Navigator.pop(context) : _load,
              child: Text(_invalid ? 'Quay lại đăng nhập' : 'Tải lại')),
          ],
          if (_working) const LinearProgressIndicator(),
          if (_addresses.isEmpty && _error == null) const Text('Bạn chưa có địa chỉ giao hàng. Nhấn + để thêm địa chỉ.'),
          for (final address in _addresses) Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(address.title, style: Theme.of(context).textTheme.titleMedium),
              if (address.isDefault) const Chip(avatar: Icon(Icons.check_circle_outline), label: Text('Mặc định')),
              SelectableText(address.address), Text(address.phone),
              Wrap(spacing: 8, children: [
                if (!address.isDefault)
                  TextButton.icon(onPressed: _working || _invalid ? null : () => _setDefault(address),
                    icon: const Icon(Icons.check_circle_outline), label: const Text('Đặt làm mặc định')),
                TextButton.icon(onPressed: _working || _invalid ? null : () => _edit(address),
                  icon: const Icon(Icons.edit_outlined), label: const Text('Sửa')),
                TextButton.icon(onPressed: _working || _invalid ? null : () => _delete(address),
                  icon: const Icon(Icons.delete_outline), label: const Text('Xóa')),
              ]),
            ]))),
        ]))),
  );
}
