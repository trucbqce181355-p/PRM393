// Author: Chih An (GitHub: ChangChinAn)
// UC16: Form tạo/sửa nội dung yêu cầu chưa được xử lý.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/support_request.dart';
import '../../services/login_service.dart';

class SupportRequestFormScreen extends StatefulWidget {
  const SupportRequestFormScreen({super.key, required this.session, required this.service, this.request});
  final LoginResult session;
  final LoginService service;
  final SupportRequest? request;
  @override
  State<SupportRequestFormScreen> createState() => _SupportRequestFormScreenState();
}
class _SupportRequestFormScreenState extends State<SupportRequestFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _reason;
  late final TextEditingController _description;
  late final TextEditingController _order;
  StreamSubscription<LoginResult?>? _subscription;
  bool _busy = false;
  bool _invalid = false;
  bool _locked = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _reason = TextEditingController(text: widget.request?.reason ?? '');
    _description = TextEditingController(text: widget.request?.description ?? '');
    _order = TextEditingController(text: widget.request?.orderId ?? '');
    _locked = widget.request != null && !widget.request!.isPending;
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || session?.token == widget.session.token) return;
      setState(() { _invalid = true; _error = 'Phiên đã hết hạn. Vui lòng đăng nhập lại.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
  }
  Future<void> _save() async {
    if (_busy || _invalid || _locked || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      await widget.service.saveRequest(widget.session, id: widget.request?.id,
        reason: _reason.text, description: _description.text, orderId: _order.text);
      if (mounted && !_invalid) Navigator.pop(context, true);
    } on LoginException catch (error) {
      if (mounted) setState(() {
        _error = error.message; _invalid = error.code == 'session_expired';
        _locked = error.code == 'request_not_pending';
      });
    } finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _reason.dispose(); _description.dispose(); _order.dispose(); super.dispose();
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: Scaffold(
    appBar: AppBar(title: Text(widget.request == null ? 'Tạo yêu cầu hỗ trợ' : 'Sửa yêu cầu hỗ trợ')),
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
        child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(controller: _order, readOnly: widget.request != null, enabled: !_busy && !_invalid && !_locked,
              decoration: const InputDecoration(labelText: 'Mã đơn hàng của bạn (không bắt buộc)'),
              validator: (value) => (value?.length ?? 0) <= 100 ? null : 'Mã đơn hàng tối đa 100 ký tự.'),
            const SizedBox(height: 16),
            TextFormField(controller: _reason, enabled: !_busy && !_invalid && !_locked, maxLength: 300,
              decoration: const InputDecoration(labelText: 'Lý do / tiêu đề yêu cầu'),
              validator: (value) => value == null || value.trim().isEmpty || value.length > 300
                ? 'Nhập lý do từ 1 đến 300 ký tự.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _description, enabled: !_busy && !_invalid && !_locked,
              minLines: 4, maxLines: 8, maxLength: 4000,
              decoration: const InputDecoration(labelText: 'Nội dung chi tiết'),
              validator: (value) => value == null || value.trim().isEmpty || value.length > 4000
                ? 'Nhập nội dung từ 1 đến 4.000 ký tự.' : null),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy || _invalid || _locked ? null : _save,
              child: Text(_busy ? 'Đang lưu...' : widget.request == null ? 'Gửi yêu cầu' : 'Lưu thay đổi')),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context, _locked),
              child: Text(_locked ? 'Quay lại để tải trạng thái mới' : 'Quay lại')),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ])),
      ),
    ))),
  ));
}
