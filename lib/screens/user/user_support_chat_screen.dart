// Author: Chih An (GitHub: ChangChinAn)
// UC15: Gửi nội dung hỗ trợ, xem phản hồi và trả lời hội thoại theo quyền tài khoản.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/support_message.dart';
import '../../services/login_service.dart';

class UserSupportChatScreen extends StatefulWidget {
  const UserSupportChatScreen({super.key, required this.session, required this.service, this.conversationId});
  final LoginResult session;
  final LoginService service;
  final String? conversationId;
  @override
  State<UserSupportChatScreen> createState() => _UserSupportChatScreenState();
}
class _UserSupportChatScreenState extends State<UserSupportChatScreen> with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<LoginResult?>? _subscription;
  Timer? _poll;
  SupportSnapshot? _snapshot;
  bool _refreshing = false;
  bool _sending = false;
  bool _invalid = false;
  bool _foreground = true;
  String? _error;
  bool get _inbox => widget.session.customer.role == 'admin' && widget.conversationId == null;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = LoginService.sessionEvents.listen((session) {
      if (!mounted || session?.token == widget.session.token) return;
      setState(() { _snapshot = null; _invalid = true; _message.clear(); _error = 'Phiên đã hết hạn. Vui lòng đăng nhập lại.'; });
      if (ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
    });
    unawaited(_load());
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_foreground && ModalRoute.of(context)?.isCurrent == true) unawaited(_load());
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_load());
  }
  Future<void> _load() async {
    if (_refreshing || _sending || _invalid) return;
    setState(() => _refreshing = true);
    final wasNearBottom = !_scroll.hasClients || _scroll.position.extentAfter < 120;
    try {
      final snapshot = await widget.service.fetchSupport(widget.session, conversationId: widget.conversationId);
      if (!mounted || _invalid) return;
      final previous = _snapshot?.messages;
      final previousId = previous == null || previous.isEmpty ? null : previous.last.id;
      final changed = previousId != (snapshot.messages.isEmpty ? null : snapshot.messages.last.id);
      setState(() { _snapshot = snapshot; _error = null; });
      if (!_inbox && changed && wasNearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      }
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _refreshing = false); }
  }
  Future<void> _send() async {
    if (_sending || _refreshing || _invalid || !_form.currentState!.validate()) return;
    final text = _message.text.trim();
    setState(() { _sending = true; _error = null; });
    bool sent = false;
    try {
      await widget.service.sendSupportMessage(widget.session, text, conversationId: widget.conversationId);
      if (!mounted || _invalid) return;
      _message.clear();
      sent = true;
    } on LoginException catch (error) {
      if (mounted) setState(() { _error = error.message; _invalid = error.code == 'session_expired'; });
    } finally { if (mounted) setState(() => _sending = false); }
    if (mounted && sent && !_invalid) await _load();
  }
  Future<void> _open(SupportConversation conversation) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => UserSupportChatScreen(
      session: widget.session, service: widget.service, conversationId: conversation.email)));
    if (!mounted) return;
    if (_invalid) { Navigator.pop(context); return; }
    await _load();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel(); unawaited(_subscription?.cancel());
    _message.dispose(); _scroll.dispose(); super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: Text(_inbox ? 'Hội thoại hỗ trợ khách hàng' : 'Yêu cầu / tin nhắn hỗ trợ'), actions: [
        IconButton(onPressed: _refreshing || _sending || _invalid ? null : _load,
          tooltip: 'Tải phản hồi mới', icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
        child: Column(children: [
          if (_refreshing || _sending) const LinearProgressIndicator(),
          if (widget.conversationId != null) Padding(padding: const EdgeInsets.all(12), child: Text(widget.conversationId!)),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            TextButton(onPressed: _invalid ? () => Navigator.pop(context) : _refreshing || _sending ? null : _load,
              child: Text(_invalid ? 'Quay lại đăng nhập' : 'Thử tải lại')),
          ])),
          Expanded(child: snapshot == null ? const Center(child: Text('Đang chờ dữ liệu hội thoại.'))
            : _inbox ? snapshot.conversations.isEmpty ? const Center(child: Text('Chưa có hội thoại hỗ trợ.'))
              : ListView(children: [for (final conversation in snapshot.conversations)
                ListTile(title: Text(conversation.email), subtitle: Text(conversation.lastMessage,
                  maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => _open(conversation))])
            : snapshot.messages.isEmpty ? const Center(child: Text('Gửi nội dung cần hỗ trợ để bắt đầu hội thoại.'))
              : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(16),
                itemCount: snapshot.messages.length, itemBuilder: (context, index) {
                  final message = snapshot.messages[index];
                  final fromSupport = message.senderRole == 'admin';
                  return Card(child: Padding(padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fromSupport ? 'Phản hồi từ hỗ trợ' : message.senderName.isEmpty ? 'Khách hàng' : message.senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6), SelectableText(message.message),
                      const SizedBox(height: 6), Text(message.createdAt.toLocal().toString().split('.').first,
                        style: Theme.of(context).textTheme.bodySmall),
                    ])));
                })),
          if (!_inbox && !_invalid) Padding(padding: const EdgeInsets.all(16),
            child: Form(key: _form, child: Column(children: [
              TextFormField(controller: _message, enabled: !_sending, minLines: 1, maxLines: 4, maxLength: 4000,
                decoration: const InputDecoration(labelText: 'Nội dung yêu cầu / tin nhắn hỗ trợ'),
                validator: (value) => value == null || value.trim().isEmpty || value.length > 4000
                  ? 'Nhập nội dung từ 1 đến 4.000 ký tự.' : null),
              FilledButton.icon(onPressed: _sending || _refreshing ? null : _send,
                icon: const Icon(Icons.send), label: Text(_sending ? 'Đang gửi...' : 'Gửi')),
            ]))),
        ]),
      ))),
    );
  }
}
