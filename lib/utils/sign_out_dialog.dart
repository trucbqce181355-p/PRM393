import 'package:flutter/material.dart';

import '../services/auth_service.dart';

bool _dialogOpen = false;

Future<void> showSignOutDialog(BuildContext context) async {
  if (_dialogOpen || !context.mounted) return;
  _dialogOpen = true;
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const _SignOutDialog(),
    );
  } finally {
    _dialogOpen = false;
  }
}

class _SignOutDialog extends StatefulWidget {
  const _SignOutDialog();
  @override
  State<_SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<_SignOutDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message
              : 'Không thể đăng xuất. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Đăng xuất'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Đang đăng xuất...'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _signOut,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
