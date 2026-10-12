import 'package:flutter/material.dart';
import 'screens/user/user_home_screen.dart';
import 'services/storage_service.dart';

import 'services/data_service.dart';
import 'services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await MongoDBService.connect(); // Initialize MongoDB trước để lấy dữ liệu
  await DataService.init(); // Initialize Hive database và load dữ liệu
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const UserHomeScreen(),
    );
  }
}
