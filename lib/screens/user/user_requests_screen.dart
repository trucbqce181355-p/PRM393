// Author: Chih An (GitHub: ChangChinAn)
// UC16: Danh sách yêu cầu, xem chi tiết và sửa/hủy khi trạng thái còn pending.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/support_request.dart';
import '../../services/login_service.dart';
import 'support_request_form_screen.dart';

class UserRequestsScreen extends StatefulWidget {
  const UserRequestsScreen({super.key, required this.session, required this.service});
  final LoginResult session;
  final LoginService service;
  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}
class _UserRequestsScreenState extends State<UserRequestsScreen> with WidgetsBindingObserver {
  StreamSubscription<LoginResult?>? _subscription;
  List<SupportRequest> _requests = [];
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
      setState(() { _requests = []; _invalid = true; _error = 'Phiên đã hết hạn. Vui lòng đăng nhập lại.'; });
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
    setState(() { _loading = true; _requests = []; _error = null; });
    try {
      final requests = await widget.service.fetchRequests(widget.session);
      if (mounted && !_invalid) setState(() => _requests = requests);
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _edit([SupportRequest? request]) async {
    if (_working || _loading || _invalid || (request != null && !request.isPending)) return;
    setState(() => _working = true);
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>
      SupportRequestFormScreen(session: widget.session, service: widget.service, request: request)));
    if (!mounted) return;
    setState(() => _working = false);
    if (_invalid) { Navigator.pop(context); return; }
    if (saved == true) await _load();
  }
  Future<void> _cancel(SupportRequest request) async {
    if (_working || _loading || _invalid || !request.isPending) return;
    setState(() => _working = true);
    bool refresh = false;
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy yêu cầu'), content: Text('Bạn muốn hủy yêu cầu "${request.reason}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Quay lại')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hủy yêu cầu')),
        ]));
      if (!mounted || _invalid || confirmed != true) return;
      await widget.service.cancelRequest(widget.session, request.id);
      refresh = true;
    } on LoginException catch (error) {
      if (!mounted) return;
      setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
      if (error.code == 'request_not_pending') {
        refresh = true;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally { if (mounted) setState(() => _working = false); }
    if (mounted && refresh && !_invalid) await _load();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel()); super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yêu cầu của tôi'), actions: [
      IconButton(onPressed: _loading || _working || _invalid ? null : _load,
        tooltip: 'Tải lại yêu cầu', icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: FloatingActionButton(onPressed: _loading || _working || _invalid ? null : () => _edit(),
      tooltip: 'Tạo yêu cầu', child: const Icon(Icons.add)),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton(onPressed: _working ? null : _invalid ? () => Navigator.pop(context) : _load,
              child: Text(_invalid ? 'Quay lại đăng nhập' : 'Tải lại')),
          ],
          if (_working) const LinearProgressIndicator(),
          if (_requests.isEmpty && _error == null) const Text('Bạn chưa có yêu cầu. Nhấn + để tạo yêu cầu mới.'),
          for (final request in _requests) Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.reason, style: Theme.of(context).textTheme.titleMedium),
              Chip(label: Text(request.statusLabel)),
              SelectableText('Mã yêu cầu: ${request.id}'),
              if (request.orderId.isNotEmpty) SelectableText('Mã đơn hàng: ${request.orderId}'),
              Text(request.createdAt.toLocal().toString().split('.').first),
              const SizedBox(height: 8), SelectableText(request.description),
              if (request.adminReply?.isNotEmpty == true) ...[
                const Divider(), const Text('Phản hồi từ hỗ trợ:'), SelectableText(request.adminReply!),
              ],
              if (request.isPending) Wrap(spacing: 8, children: [
                TextButton.icon(onPressed: _working || _invalid ? null : () => _edit(request),
                  icon: const Icon(Icons.edit_outlined), label: const Text('Sửa')),
                TextButton.icon(onPressed: _working || _invalid ? null : () => _cancel(request),
                  icon: const Icon(Icons.cancel_outlined), label: const Text('Hủy yêu cầu')),
              ]),
            ]))),
        ]))),
  );
}
