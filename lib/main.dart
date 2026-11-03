// Author: Chih An (GitHub: ChangChinAn)
// UC05: Mở đăng nhập email/mật khẩu và các liên kết đăng ký/quên mật khẩu.
import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';

void main() => runApp(const MyApp());

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
