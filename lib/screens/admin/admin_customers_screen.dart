// Author: Chih An (GitHub: ChangChinAn)
// UC17–UC18: Xem khách hàng và xác nhận khóa/mở khóa tài khoản.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/customer_summary.dart';
import '../../services/login_service.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key, required this.session, required this.service});
  final LoginResult session;
  final LoginService service;
  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}
class _AdminCustomersScreenState extends State<AdminCustomersScreen> with WidgetsBindingObserver {
  final _search = TextEditingController();
  StreamSubscription<LoginResult?>? _subscription;
  List<CustomerSummary> _customers = [];
  bool _loading = false;
  bool _denied = false;
  String? _updatingId;
  int _filter = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || (session?.token == widget.session.token && session?.customer.role == 'admin')) return;
      setState(() { _customers = []; _denied = true; _error = 'Phiên hoặc quyền quản trị đã thay đổi.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
    unawaited(_load());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }
  Future<void> _load() async {
    if (_loading || _denied || _updatingId != null) return;
    setState(() { _loading = true; _error = null; _customers = []; });
    try {
      final customers = await widget.service.fetchCustomers(widget.session);
      if (mounted && !_denied) setState(() => _customers = customers);
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _denied = ['session_expired', 'admin_required'].contains(error.code); });
    } finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _changeStatus(CustomerSummary customer) async {
    if (_loading || _denied || _updatingId != null) return;
    final targetActive = !customer.isActive;
    final action = targetActive ? 'Mở khóa' : 'Khóa';
    setState(() => _updatingId = customer.id);
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: Text('$action tài khoản'),
        content: Text(targetActive
          ? 'Mở khóa tài khoản ${customer.email}? Khách hàng cần đăng nhập lại.'
          : 'Khóa tài khoản ${customer.email}? Các phiên hiện tại sẽ bị thu hồi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action)),
        ]));
      if (!mounted || _denied || confirmed != true) return;
      final updated = await widget.service.updateCustomerStatus(widget.session, customer.id, targetActive);
      if (!mounted || _denied) return;
      setState(() {
        _customers = _customers.map((item) => item.id == updated.id ? updated : item).toList();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(targetActive
        ? 'Đã mở khóa. Khách hàng có thể đăng nhập lại.' : 'Đã khóa tài khoản và thu hồi các phiên cũ.')));
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _denied = ['session_expired', 'admin_required'].contains(error.code);
        if (_denied) _customers = [];
      });
    } finally { if (mounted) setState(() => _updatingId = null); }
  }

  List<CustomerSummary> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _customers.where((customer) =>
      (_filter == 0 || (_filter == 1 ? customer.isActive : !customer.isActive)) &&
      (query.isEmpty || customer.name.toLowerCase().contains(query) ||
        customer.email.toLowerCase().contains(query) || customer.phone.contains(query))).toList();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel()); _search.dispose(); super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    const filterLabels = ['Tất cả', 'Hoạt động', 'Tạm khóa'];
    final customers = _filtered;
    final active = _customers.where((customer) => customer.isActive).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách khách hàng'), actions: [
        IconButton(onPressed: _loading || _denied || _updatingId != null ? null : _load,
          tooltip: 'Tải lại khách hàng', icon: const Icon(Icons.refresh)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!), const SizedBox(height: 16),
            FilledButton(onPressed: _denied ? () => Navigator.pop(context) : _load,
              child: Text(_denied ? 'Quay lại' : 'Thử lại')),
          ])))
        : SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Tổng: ${_customers.length} • Hoạt động: $active • Tạm khóa: ${_customers.length - active}'),
                const SizedBox(height: 16),
                TextField(controller: _search, onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: 'Tìm theo tên, email hoặc số điện thoại',
                    prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(
                      onPressed: () => setState(() => _search.clear()), icon: const Icon(Icons.clear)))),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  for (int index = 0; index < 3; index++) ChoiceChip(
                    label: Text(filterLabels[index]), selected: _filter == index,
                    onSelected: (_) => setState(() => _filter = index)),
                ]),
              ])),
            Expanded(child: customers.isEmpty ? Center(child: Text(_customers.isEmpty
              ? 'Chưa có khách hàng.' : 'Không có khách hàng phù hợp.'))
              : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: customers.length, itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(child: Padding(padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(customer.name.isEmpty ? 'Chưa cập nhật họ tên' : customer.name,
                        style: Theme.of(context).textTheme.titleMedium),
                      SelectableText(customer.email),
                      SelectableText(customer.phone.isEmpty ? 'Chưa cập nhật số điện thoại' : customer.phone),
                      SelectableText('Mã khách hàng: ${customer.id}'),
                      Chip(avatar: Icon(customer.isActive ? Icons.check_circle_outline : Icons.lock_outline),
                        label: Text(customer.isActive ? 'Hoạt động' : 'Tạm khóa')),
                      if (customer.createdAt != null)
                        Text('Ngày tạo: ${customer.createdAt!.toLocal().toString().split('.').first}'),
                      TextButton.icon(onPressed: _updatingId != null || _denied ? null : () => _changeStatus(customer),
                        icon: Icon(customer.isActive ? Icons.lock_outline : Icons.lock_open),
                        label: Text(_updatingId == customer.id ? 'Đang xử lý...'
                          : customer.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản')),
                    ])));
                })),
          ]),
        ))),
    );
  }
}
