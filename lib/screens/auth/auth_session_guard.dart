import 'dart:async';

import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import 'auth_gate.dart';

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
  StreamSubscription<String?>? _subscription;
  String? _previousUser;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _previousUser = AuthRepository.currentUserId;
    _subscription = AuthRepository.authStateChanges.listen((uid) {
      final ended = _previousUser != null && uid == null;
      _previousUser = uid;
      if (!ended) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || AuthRepository.currentUserId != null) return;
        widget.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        AuthRepository.sessionCustomer != null) {
      unawaited(
        AuthRepository.fetchCustomerProfile().then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {},
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
