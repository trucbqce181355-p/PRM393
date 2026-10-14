import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_wrapper.dart';

/// Clears the navigation stack when an accepted session expires or is rejected.
class AuthSessionGuard extends StatefulWidget {
  const AuthSessionGuard({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AuthSessionGuard> createState() => _AuthSessionGuardState();
}

class _AuthSessionGuardState extends State<AuthSessionGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.sessionInvalidations.addListener(_onSessionInvalidated);
  }

  void _onSessionInvalidated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AuthService.isLoggedIn) return;
      widget.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AuthService.refreshSession());
    }
  }

  @override
  void dispose() {
    AuthService.sessionInvalidations.removeListener(_onSessionInvalidated);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
