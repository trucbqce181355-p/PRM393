import 'package:flutter/material.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/mongodb_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Khởi tạo Local Storage (SharedPreferences)
  await StorageService.init();

  // 2. Khởi tạo & nạp phiên đăng nhập từ Local Storage (Token)
  await AuthService.initSession();

  // 3. Kết nối MongoDB và load cache
  await MongoDBService.connect();
  await DataService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruitopia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // BƯỚC 1: AuthWrapper kiểm tra Token local để mở UserHomeScreen hoặc LoginScreen
      home: const AuthWrapper(),
    );
  }
}
