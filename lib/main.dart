// Author: Chih An (GitHub: ChangChinAn)
// UC01: Điểm khởi chạy giao diện yêu cầu/gửi lại OTP xác minh email.
import 'package:flutter/material.dart';

import 'screens/auth/register_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fruitopia - Email OTP',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
    home: const RegisterScreen(),
  );
}
