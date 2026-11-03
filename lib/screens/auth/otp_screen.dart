// Author: Chih An (GitHub: ChangChinAn)
// UC02: Nhập OTP, hiển thị hạn dùng/lượt thử và kết quả xác minh.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/otp_request_service.dart';
import '../../services/otp_verification_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.challenge,
    this.service,
    this.clock,
  });
  final OtpEmailChallenge challenge;
  final OtpVerificationService? service;
  final DateTime Function()? clock;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  late final OtpVerificationService _service;
  late final DateTime _expiresAt;
  late int _remainingAttempts;
  Timer? _timer;
  bool _busy = false;
  bool _blocked = false;
  String? _error;
  OtpVerificationResult? _result;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  int get _seconds =>
      ((_expiresAt.difference(_now).inMilliseconds + 999) ~/ 1000).clamp(
        0,
        86400,
      );

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? OtpVerificationService();
    _expiresAt =
        widget.challenge.expiresAt ??
        _now.add(Duration(seconds: widget.challenge.expiresIn));
    _remainingAttempts = widget.challenge.maxAttempts;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (_seconds == 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (_busy || _blocked || _seconds == 0 || _result != null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.verify(widget.challenge.id, _otp.text);
      if (!mounted) return;
      setState(() {
        _result = result;
        _timer?.cancel();
      });
    } on OtpVerificationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _remainingAttempts = error.remainingAttempts ?? _remainingAttempts;
        _blocked = error.terminal;
        if (_blocked) _timer?.cancel();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.challenge.purpose == 'password_reset'
      ? 'Xác minh đặt lại mật khẩu' : 'Xác minh OTP')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mã đã gửi đến ${widget.challenge.email}'),
                  const SizedBox(height: 16),
                  if (_result == null) ...[
                    Text(
                      'Thời gian còn lại: ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                    ),
                    Text('Số lần thử còn lại: $_remainingAttempts'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otp,
                      enabled: !_busy && !_blocked && _seconds > 0,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Mã OTP',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          RegExp(r'^\d{6}$').hasMatch(value ?? '')
                          ? null
                          : 'Vui lòng nhập đủ 6 chữ số OTP.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy || _blocked || _seconds == 0
                          ? null
                          : _verify,
                      child: Text(_busy ? 'Đang xác minh...' : 'Xác minh OTP'),
                    ),
                    if (_seconds == 0)
                      const Text(
                        'Mã OTP đã hết hạn. Vui lòng quay lại để gửi mã mới.',
                      ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại để gửi mã mới'),
                    ),
                  ] else ...[
                    const Text(
                      'Email đã được xác minh thành công.',
                      style: TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, _result),
                      child: const Text('Hoàn tất xác minh'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
