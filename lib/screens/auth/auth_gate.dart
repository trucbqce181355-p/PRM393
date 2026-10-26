import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../models/customer.dart';
import '../admin/admin_dashboard_screen.dart';
import '../user/user_home_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import 'link_google_screen.dart';
import '../../services/auth_api_service.dart';
import '../user/checkout_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.redirectToCheckout = false});
  final bool redirectToCheckout;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<String?> _stream;
  Future<Customer?>? _profile;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _stream = AuthRepository.authStateChanges;
  }

  Widget _error(String message) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (AuthRepository.isAwaitingGoogle) {
                  AuthRepository.restoreError = null;
                } else {
                  await AuthRepository.restoreSession();
                }
                if (mounted) {
                  setState(() {
                    _profile = null;
                    _uid = null;
                  });
                }
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    initialData: AuthRepository.currentUserId,
    stream: _stream,
    builder: (context, snapshot) {
      if (AuthRepository.restoreError != null) {
        return _error(AuthRepository.restoreError!);
      }
      final uid = snapshot.data;
      if (uid == null) {
        _profile = null;
        _uid = null;
        return const LoginScreen();
      }
      if (_uid != uid || _profile == null) {
        _uid = uid;
        _profile = AuthRepository.fetchCustomerProfile();
      }
      return FutureBuilder<Customer?>(
        future: _profile,
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (profile.hasError) {
            final error = profile.error;
            if (error is BackendAuthException &&
                error.code == 'account_link_required') {
              return const LinkGoogleScreen();
            }
            return _error(
              error is StateError
                  ? error.message
                  : 'Không thể tải hồ sơ. Vui lòng thử lại.',
            );
          }
          final customer = profile.data;
          if (customer == null) return const LoginScreen();
          if (!customer.isActive) return _error('Tài khoản đã bị khóa.');
          if (customer.role == 'admin') return const AdminDashboardScreen();
          if (!AuthRepository.hasCompletedProfile) {
            return ProfileSetupScreen(
              initialName: customer.name,
              initialPhone: customer.phone,
              initialEmail: customer.email,
              authenticatedProfile: true,
              needsPassword: !customer.hasPassword,
              redirectToCheckout: widget.redirectToCheckout,
            );
          }
          return widget.redirectToCheckout
              ? const CheckoutScreen()
              : const UserHomeScreen();
        },
      );
    },
  );
}
