import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../user/user_home_screen.dart';
import 'login_screen.dart';

/// Routes using the accepted backend identity; persistent restoration is added in UC 8.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isLoggedIn) {
      return const UserHomeScreen();
    }
    return const LoginScreen();
  }
}
