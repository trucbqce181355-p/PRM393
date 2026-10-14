import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../user/user_home_screen.dart';
import 'login_screen.dart';

/// Bước 1: Mở app -> Kiểm tra xem Token phiên đăng nhập đã có ở Local chưa.
/// - Nếu đã có Token: Vào thẳng UserHomeScreen
/// - Nếu chưa có Token: Vào LoginScreen (Chọn Google hoặc SĐT)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (StorageService.isLoggedIn()) {
      return const UserHomeScreen();
    }
    return const LoginScreen();
  }
}
