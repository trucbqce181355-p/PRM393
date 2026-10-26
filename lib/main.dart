import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/supabase_config.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/auth_session_guard.dart';
import 'services/storage_service.dart';
import 'services/data_service.dart';
import 'services/mongodb_service.dart';
import 'repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await MongoDBService.connect(); // Kết nối local DB cho dev
  await DataService.init(); // Initialize Hive database và load dữ liệu

  if (SupabaseConfig.isConfigured) {
    final prefs = await SharedPreferences.getInstance();
    final projectRef = Uri.parse(SupabaseConfig.url).host.split('.').first;
    await prefs.remove('sb-$projectRef-auth-token');
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  }

  if (SupabaseConfig.isConfigured) await AuthRepository.restoreSession();

  runApp(MyApp(supabaseConfigured: SupabaseConfig.isConfigured));
}

class MyApp extends StatelessWidget {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  final bool supabaseConfigured;

  const MyApp({super.key, required this.supabaseConfigured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) => supabaseConfigured
          ? AuthSessionGuard(
              navigatorKey: _navigatorKey,
              child: child ?? const SizedBox.shrink(),
            )
          : child ?? const SizedBox.shrink(),
      title: 'Fruitopia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: supabaseConfigured ? const AuthGate() : const SupabaseSetupScreen(),
    );
  }
}

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cần cấu hình Supabase',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Tạo supabase.env.json từ supabase.env.example.json, điền Project URL và publishable key, sau đó chạy:',
              ),
              SizedBox(height: 12),
              SelectableText(
                'flutter run -d windows --dart-define-from-file=supabase.env.json',
              ),
              SizedBox(height: 12),
              Text(
                'Xem docs/supabase_auth_setup.md để cấu hình Google OAuth và SMS OTP.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
