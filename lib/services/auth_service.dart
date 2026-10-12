import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import '../models/customer.dart';
import 'data_service.dart';
import 'mongodb_service.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _token;
  static String? _userName;
  static String? _userEmail;
  static String? _expectedOtp;

  static bool get isLoggedIn => _isLoggedIn;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;

  static Customer? get currentUser {
    if (!_isLoggedIn || _userEmail == null) return null;
    try {
      return DataService.customers.firstWhere((c) => c.email == _userEmail);
    } catch (e) {
      return null;
    }
  }

  static String? _pendingEmail;

  // Trả về chuỗi rỗng nếu thành công, hoặc chuỗi lỗi nếu thất bại
  static Future<String> loginWithEmail(String targetEmail) async {
    _pendingEmail = targetEmail;
    final random = Random();
    _expectedOtp = (100000 + random.nextInt(900000)).toString();

    String username = 'huet61189@gmail.com';
    String password = 'cvyasfhgklsxvfpf';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Fruitopia OTP')
      ..recipients.add(targetEmail)
      ..subject = 'Mã xác thực OTP của bạn'
      ..text = 'Mã OTP của bạn là: $_expectedOtp\nXin đừng chia sẻ mã này cho bất kỳ ai.';

    try {
      await send(message, smtpServer);
      print('Đã gửi email OTP $_expectedOtp đến $targetEmail');
      return ''; // Thành công
    } catch (e) {
      print('Lỗi gửi email: $e');
      print('Mã OTP để bạn nhập test: $_expectedOtp');
      return e.toString(); // Trả về lỗi
    }
  }

  static Future<bool> verifyOTP(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return otp == _expectedOtp || otp == '123456'; // Fallback 123456
  }

  static Future<void> registerCustomer(String name, String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (_pendingEmail != null) {
      final newCustomer = Customer(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: _pendingEmail!,
        password: password,
        phone: phone,
        totalSpent: 0.0,
        totalOrders: 0,
        isActive: true,
        memberTier: 'Đồng',
      );
      
      await DataService.addCustomer(newCustomer);
      
      // THÊM: Lưu vào MongoDB
      try {
        var usersCollection = MongoDBService.getCollection("users");
        await usersCollection.insertOne({
          "name": name,
          "email": _pendingEmail,
          "phone": phone,
          "password": password, // Lưu ý: trong thực tế nên hash password
          "role": "customer",
          "created_at": DateTime.now().toIso8601String()
        });
        print("Đã lưu user mới vào MongoDB");
      } catch (e) {
        print("Lỗi khi lưu user vào MongoDB: $e");
      }

      _userName = name;
      _userEmail = _pendingEmail;
      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      _isLoggedIn = true;
    }
  }

  static Future<void> saveProfile(String name, String email) async {
    await Future.delayed(const Duration(seconds: 1));
    _userName = name;
    _userEmail = email;
    _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    _isLoggedIn = true;
  }

  static void logout() {
    _isLoggedIn = false;
    _token = null;
    _userName = null;
    _userEmail = null;
    // Clear SharedPreferences here in a real app
  }

  static Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'admin@gmail.com' && password == '123456') {
      _userName = 'Admin';
      _token = 'mock_admin_token';
      _isLoggedIn = true;
      return 'admin';
    }

    try {
      final customer = DataService.customers.firstWhere(
        (c) => c.email == email && c.password == password
      );
      
      if (!customer.isActive) {
        throw Exception('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ CSKH.');
      }

      _userName = customer.name;
      _userEmail = customer.email;
      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      _isLoggedIn = true;
      return 'customer';
    } catch (e) {
      if (e is Exception && e.toString().contains('bị khóa')) {
        rethrow;
      }
      throw Exception('Email hoặc mật khẩu không chính xác!');
    }
  }
}
