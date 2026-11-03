// Author: Chih An (GitHub: ChangChinAn)
// UC11–UC16: Hồ sơ, địa chỉ, hội thoại và mở danh sách yêu cầu hỗ trợ.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/customer_profile.dart';
import '../../services/login_service.dart';
import 'user_edit_profile_screen.dart';
import 'user_addresses_screen.dart';
import 'user_support_chat_screen.dart';
import 'user_requests_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.session, required this.service});
  final LoginResult session;
  final LoginService service;
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with WidgetsBindingObserver {
  StreamSubscription<LoginResult?>? _subscription;
  CustomerProfile? _profile;
  String? _error;
  bool _loading = false;
  bool _editing = false;
  bool _sessionInvalid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || session?.token == widget.session.token) return;
      setState(() { _profile = null; _sessionInvalid = true; _error = 'Phiên đã hết hạn hoặc thay đổi. Vui lòng đăng nhập lại.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_editing && !_sessionInvalid) unawaited(_load());
  }

  Future<void> _edit() async {
    final profile = _profile;
    if (_loading || _editing || _sessionInvalid || profile == null) return;
    setState(() => _editing = true);
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>
      UserEditProfileScreen(session: widget.session, service: widget.service, profile: profile)));
    if (!mounted) return;
    setState(() => _editing = false);
    if (_sessionInvalid) {
      Navigator.pop(context);
      return;
    }
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin cá nhân.')));
      await _load();
    }
  }

  Future<void> _openAddresses() async {
    if (_loading || _editing || _sessionInvalid) return;
    setState(() => _editing = true);
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
      UserAddressesScreen(session: widget.session, service: widget.service)));
    if (!mounted) return;
    setState(() => _editing = false);
    if (_sessionInvalid) Navigator.pop(context);
  }

  Future<void> _openSupport() async {
    if (_loading || _editing || _sessionInvalid) return;
    setState(() => _editing = true);
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
      UserSupportChatScreen(session: widget.session, service: widget.service)));
    if (!mounted) return;
    setState(() => _editing = false);
    if (_sessionInvalid) Navigator.pop(context);
  }

  Future<void> _openRequests() async {
    if (_loading || _editing || _sessionInvalid) return;
    setState(() => _editing = true);
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
      UserRequestsScreen(session: widget.session, service: widget.service)));
    if (!mounted) return;
    setState(() => _editing = false);
    if (_sessionInvalid) Navigator.pop(context);
  }

  Future<void> _load() async {
    if (_loading || _editing || _sessionInvalid) return;
    setState(() { _loading = true; _profile = null; _error = null; });
    try {
      final profile = await widget.service.fetchProfile(widget.session);
      if (!mounted || _sessionInvalid) return;
      setState(() => _profile = profile);
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; _sessionInvalid = error.code == 'session_expired'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Widget _field(String label, String value) => ListTile(
    title: Text(label), subtitle: SelectableText(value.isEmpty ? 'Chưa cập nhật' : value));

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân'), actions: [
        IconButton(onPressed: _loading || _editing || _sessionInvalid ? null : _load,
          tooltip: 'Tải lại hồ sơ', icon: const Icon(Icons.refresh)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!), const SizedBox(height: 16),
            FilledButton(onPressed: _sessionInvalid ? () => Navigator.pop(context) : _load,
              child: Text(_sessionInvalid ? 'Quay lại đăng nhập' : 'Thử lại')),
          ])))
        : profile == null ? const SizedBox.shrink()
        : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Icon(Icons.account_circle, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Card(child: Column(children: [
              _field('Họ và tên', profile.name),
              _field('Email', profile.email),
              _field('Số điện thoại', profile.phone),
              _field('Loại tài khoản', profile.role == 'admin' ? 'Quản trị viên' : 'Khách hàng'),
            ])),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _editing ? null : _edit,
              icon: const Icon(Icons.edit_outlined), label: const Text('Chỉnh sửa thông tin cá nhân')),
            OutlinedButton.icon(onPressed: _editing ? null : _openAddresses,
              icon: const Icon(Icons.location_on_outlined), label: const Text('Địa chỉ giao hàng')),
            OutlinedButton.icon(onPressed: _editing ? null : _openSupport,
              icon: const Icon(Icons.support_agent), label: Text(profile.role == 'admin'
                ? 'Hội thoại hỗ trợ khách hàng' : 'Gửi yêu cầu/tin nhắn và xem phản hồi')),
            if (profile.role != 'admin') ...[
              OutlinedButton.icon(onPressed: _editing ? null : _openRequests,
                icon: const Icon(Icons.assignment_outlined), label: const Text('Tạo, xem và quản lý yêu cầu hỗ trợ')),
              const SizedBox(height: 16),
              Card(child: Column(children: [
                ListTile(leading: const Icon(Icons.workspace_premium, color: Colors.orange),
                  title: const Text('Hạng thành viên'), subtitle: Text(profile.memberTier)),
                _field('Tổng chi tiêu', '${profile.totalSpent.toStringAsFixed(0)}đ'),
                _field('Tổng đơn hàng chưa bị hủy', '${profile.totalOrders}'),
                const Padding(padding: EdgeInsets.all(16),
                  child: Text('Đồng: dưới 500.000đ • Bạc: từ 500.000đ • Vàng: từ 2.000.000đ. Hạng tính theo các đơn chưa bị hủy.')),
              ])),
            ],
          ]))),
    );
  }
}
