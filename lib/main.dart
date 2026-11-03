// Author: Chih An (GitHub: ChangChinAn)
// UC05–UC06: Mở đăng nhập email/Google và khởi tạo OAuth Google.
import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleAuthService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fruitopia',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
    home: const LoginScreen(),
  );
}
