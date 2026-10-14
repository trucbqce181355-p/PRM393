import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../user/user_home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

/// Routes using the accepted backend identity; persistent restoration is added in UC 8.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isLoggedIn) {
      if (AuthService.role == 'admin') return const AdminDashboardScreen();
      return AuthService.hasCompletedProfile
          ? const UserHomeScreen()
          : const ProfileSetupScreen();
    }
    return const LoginScreen();
  }
}
