import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../user/user_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

/// Routes only after the backend accepts the stored or newly issued session.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<AuthSessionStatus>(
    valueListenable: AuthService.sessionStatus,
    builder: (context, status, child) {
      if (status == AuthSessionStatus.restoring) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (status == AuthSessionStatus.unavailable) {
        return const _SessionRestoreError();
      }
      if (AuthService.isLoggedIn) {
        if (AuthService.role == 'admin') return const AdminDashboardScreen();
        return AuthService.hasCompletedProfile
            ? const UserHomeScreen()
            : const ProfileSetupScreen();
      }
      if (AuthService.sessionNotice == null) return const LoginScreen();
      return Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  AuthService.sessionNotice!,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const Expanded(child: LoginScreen()),
        ],
      );
    },
  );
}

class _SessionRestoreError extends StatefulWidget {
  const _SessionRestoreError();
  @override
  State<_SessionRestoreError> createState() => _SessionRestoreErrorState();
}

class _SessionRestoreErrorState extends State<_SessionRestoreError> {
  bool _clearing = false;

  Future<void> _discardSession() async {
    if (_clearing) return;
    setState(() => _clearing = true);
    try {
      await AuthService.logout();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa phiên đã lưu. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AuthService.restoreError ??
                  'Không thể khôi phục phiên đăng nhập.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearing ? null : AuthService.initSession,
              child: const Text('Thử lại'),
            ),
            TextButton(
              onPressed: _clearing ? null : _discardSession,
              child: Text(
                _clearing
                    ? 'Đang xóa phiên...'
                    : 'Xóa phiên đã lưu và đăng nhập lại',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
