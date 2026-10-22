import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import '../models/customer.dart';
import 'data_service.dart';
import 'mongodb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class OtpResult {
  final bool isValid;
  final String message;
  final bool isExpired;
  final bool isLocked;
  final int remainingAttempts;

  OtpResult({
    required this.isValid,
    required this.message,
    this.isExpired = false,
    this.isLocked = false,
    this.remainingAttempts = 5,
  });
}

class AuthService {
  static bool _isLoggedIn = false;
  static String? _token;
  static String? _userName;
  static String? _userEmail;
  static String? _expectedOtp;
  static String _adminPassword = '123456';

  // OTP Configuration & Tracking
  static DateTime? _otpCreatedAt;
  static int _otpAttempts = 0;
  static const int _maxOtpAttempts = 5;
  static const int _otpDurationSeconds = 120; // 2 phút

  static bool get isLoggedIn => _isLoggedIn;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;
  static String get adminPassword => _adminPassword;
  static DateTime? get otpCreatedAt => _otpCreatedAt;
  static int get otpDurationSeconds => _otpDurationSeconds;
  static int get remainingOtpAttempts => (_maxOtpAttempts - _otpAttempts).clamp(0, _maxOtpAttempts);
  static String? get pendingEmail => _pendingEmail;

  static bool get isAdmin =>
      _isLoggedIn &&
      (_userName == 'Admin' ||
          _userEmail == 'admin@gmail.com' ||
          _token == 'mock_admin_token');

  // --- 1. KHỞI TẠO, LƯU PHIÊN, KHÔI PHỤC PHIÊN & THU HỒI PHIÊN LOCAL ---
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminPassword = prefs.getString('admin_password') ?? '123456';

      // Khôi phục phiên đăng nhập local nếu có
      final savedToken = prefs.getString('auth_token');
      final savedEmail = prefs.getString('auth_user_email');
      final savedName = prefs.getString('auth_user_name');
      final expiryMillis = prefs.getInt('auth_session_expiry') ?? 0;

      if (savedToken != null && savedEmail != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > expiryMillis) {
          // Phiên đã hết hạn -> Thu hồi phiên & Xóa session local
          print('Phiên đăng nhập của $savedEmail đã hết hạn. Đang xóa phiên local...');
          await logout();
        } else {
          // Khôi phục phiên còn hạn
          _token = savedToken;
          _userEmail = savedEmail;
          _userName = savedName;
          _isLoggedIn = true;
          print('Đã khôi phục phiên đăng nhập của $savedEmail (Hạn đến: ${DateTime.fromMillisecondsSinceEpoch(expiryMillis)})');
        }
      }
    } catch (e) {
      print('Lỗi khởi tạo AuthService: $e');
      _adminPassword = '123456';
    }
  }

  // Lưu phiên đăng nhập xuống SharedPreferences
  static Future<void> saveSession({
    required String email,
    required String name,
    required String token,
    int expiryDays = 7,
  }) async {
    _token = token;
    _userName = name;
    _userEmail = email;
    _isLoggedIn = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryMillis = DateTime.now().add(Duration(days: expiryDays)).millisecondsSinceEpoch;
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_user_email', email);
      await prefs.setString('auth_user_name', name);
      await prefs.setInt('auth_session_expiry', expiryMillis);
    } catch (e) {
      print('Lỗi lưu session vào SharedPreferences: $e');
    }
  }

  // Kiểm tra phiên đăng nhập có hết hạn chưa
  static Future<bool> isSessionExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryMillis = prefs.getInt('auth_session_expiry') ?? 0;
      if (expiryMillis == 0) return true;
      return DateTime.now().millisecondsSinceEpoch > expiryMillis;
    } catch (_) {
      return true;
    }
  }

  // Thu hồi phiên và xóa sạch phiên local (Logout)
  static Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _userName = null;
    _userEmail = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_session_expiry');
      print('Đã thu hồi phiên và xóa sạch dữ liệu local.');
    } catch (e) {
      print('Lỗi xóa session local: $e');
    }
  }

  // Tương thích ngược với hàm saveProfile cũ
  static Future<void> saveProfile(String name, String email) async {
    final token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    await saveSession(email: email, name: name, token: token);
  }

  static Future<bool> changeAdminPassword(String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (oldPassword != _adminPassword) {
      return false;
    }
    _adminPassword = newPassword;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_password', newPassword);
    } catch (_) {}

    try {
      var col = MongoDBService.getCollection("users");
      await col.updateOne(
        mongo.where.eq('email', 'admin@gmail.com'),
        mongo.modify.set('password', newPassword),
      );
    } catch (e) {
      print("MongoDB error changeAdminPassword: $e");
    }
    return true;
  }

  static Customer? get currentUser {
    if (!_isLoggedIn || _userEmail == null) return null;
    try {
      return DataService.customers.firstWhere((c) => c.email.toLowerCase() == _userEmail!.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  static String? _pendingEmail;

  // --- 2. QUẢN LÝ OTP: GỬI, GỬI LẠI, KIỂM TRA HẾT HẠN & GIỚI HẠN SỐ LẦN THỬ ---

  // Gửi OTP qua Email
  static Future<String> loginWithEmail(String targetEmail) async {
    _pendingEmail = targetEmail;
    final random = Random();
    _expectedOtp = (100000 + random.nextInt(900000)).toString();
    _otpCreatedAt = DateTime.now();
    _otpAttempts = 0;

    String username = 'huet61189@gmail.com';
    String password = 'cvyasfhgklsxvfpf';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Fruitopia OTP')
      ..recipients.add(targetEmail)
      ..subject = 'Mã xác thực OTP của bạn'
      ..text = 'Mã OTP của bạn là: $_expectedOtp\n'
          'Mã có hiệu lực trong $_otpDurationSeconds giây (2 phút).\n'
          'Xin đừng chia sẻ mã này cho bất kỳ ai.';

    try {
      await send(message, smtpServer);
      print('Đã gửi email OTP $_expectedOtp đến $targetEmail (Hết hạn sau $_otpDurationSeconds giây)');
      return ''; // Thành công
    } catch (e) {
      print('Lỗi gửi email: $e');
      print('Mã OTP test: $_expectedOtp');
      return e.toString();
    }
  }

  // Gửi lại mã OTP
  static Future<String> resendOTP() async {
    if (_pendingEmail == null || _pendingEmail!.isEmpty) {
      return 'Không tìm thấy địa chỉ email để gửi lại OTP';
    }
    return await loginWithEmail(_pendingEmail!);
  }

  // Xác minh OTP có kiểm tra TTL hết hạn và giới hạn 5 lần thử
  static Future<OtpResult> verifyOTP(String otp) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1. Kiểm tra đã bị khóa do nhập sai quá 5 lần chưa
    if (_otpAttempts >= _maxOtpAttempts) {
      return OtpResult(
        isValid: false,
        message: 'Mã OTP này đã bị khóa do bạn đã nhập sai quá $_maxOtpAttempts lần. Vui lòng bấm "Gửi lại OTP"!',
        isLocked: true,
        remainingAttempts: 0,
      );
    }

    // 2. Kiểm tra thời hạn OTP (120 giây)
    if (_otpCreatedAt == null) {
      return OtpResult(
        isValid: false,
        message: 'Mã OTP chưa được khởi tạo. Vui lòng gửi lại mã OTP!',
        isExpired: true,
      );
    }

    final elapsedSeconds = DateTime.now().difference(_otpCreatedAt!).inSeconds;
    if (elapsedSeconds > _otpDurationSeconds) {
      return OtpResult(
        isValid: false,
        message: 'Mã OTP đã hết hạn sau $_otpDurationSeconds giây. Vui lòng bấm "Gửi lại mã OTP"!',
        isExpired: true,
        remainingAttempts: _maxOtpAttempts - _otpAttempts,
      );
    }

    // 3. Tăng số lần thử
    _otpAttempts++;

    // 4. Kiểm tra mã đúng (hỗ trợ mã gửi thật hoặc mã test 123456 nếu còn hạn)
    if (otp == _expectedOtp || otp == '123456') {
      _otpAttempts = 0; // Reset
      return OtpResult(
        isValid: true,
        message: 'Xác thực OTP thành công!',
        remainingAttempts: _maxOtpAttempts,
      );
    }

    // 5. Trường hợp nhập sai
    final remaining = _maxOtpAttempts - _otpAttempts;
    if (remaining <= 0) {
      return OtpResult(
        isValid: false,
        message: 'Bạn đã nhập sai 5 lần! Mã OTP này đã bị khóa. Vui lòng bấm "Gửi lại OTP" để nhận mã mới.',
        remainingAttempts: 0,
        isLocked: true,
      );
    }

    return OtpResult(
      isValid: false,
      message: 'Mã OTP không chính xác. Bạn còn $remaining lần thử.',
      remainingAttempts: remaining,
    );
  }

  // --- 3. ĐĂNG KÝ KHÁCH HÀNG THƯỜNG ---
  static Future<void> registerCustomer(String name, String phone, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

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

      try {
        var usersCollection = MongoDBService.getCollection("users");
        await usersCollection.insertOne({
          "id": newCustomer.id,
          "name": name,
          "email": _pendingEmail,
          "phone": phone,
          "password": password,
          "role": "customer",
          "memberTier": "Đồng",
          "totalSpent": 0.0,
          "totalOrders": 0,
          "isActive": true,
          "created_at": DateTime.now().toIso8601String()
        });
        print("Đã lưu user mới vào MongoDB");
      } catch (e) {
        print("Lỗi khi lưu user vào MongoDB: $e");
      }

      await saveSession(
        email: _pendingEmail!,
        name: name,
        token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  // --- 4. ĐĂNG NHẬP TRUYỀN THỐNG BẰNG EMAIL & MẬT KHẨU ---
  static Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final cleanEmail = email.trim();

    if (cleanEmail == 'admin@gmail.com' && password == _adminPassword) {
      await saveSession(
        email: 'admin@gmail.com',
        name: 'Admin',
        token: 'mock_admin_token',
      );
      return 'admin';
    }

    try {
      final customer = DataService.customers.firstWhere(
        (c) => c.email.trim().toLowerCase() == cleanEmail.toLowerCase() && c.password == password,
      );

      if (!customer.isActive) {
        throw Exception('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ CSKH.');
      }

      await saveSession(
        email: customer.email,
        name: customer.name,
        token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      return 'customer';
    } catch (e) {
      if (e is Exception && e.toString().contains('bị khóa')) {
        rethrow;
      }
      throw Exception('Email hoặc mật khẩu không chính xác!');
    }
  }

  // --- 5. ĐĂNG NHẬP BẰNG TÀI KHOẢN GOOGLE & LIÊN KẾT EMAIL ---
  static Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String name,
    String? googleId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final cleanEmail = email.trim().toLowerCase();
    final gId = googleId ?? 'google_${cleanEmail.hashCode.abs()}';

    // 1. Kiểm tra tài khoản đã tồn tại hay chưa
    final existingIndex = DataService.customers.indexWhere(
      (c) => c.email.trim().toLowerCase() == cleanEmail,
    );

    if (existingIndex != -1) {
      // Đã có tài khoản: Tự động liên kết Google với tài khoản cùng email
      final existing = DataService.customers[existingIndex];
      if (!existing.isActive) {
        throw Exception('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ CSKH.');
      }

      final updated = existing.copyWith(
        isGoogleLinked: true,
        googleId: gId,
      );
      DataService.customers[existingIndex] = updated;
      await DataService.saveCustomersToCache();

      try {
        var usersCol = MongoDBService.getCollection("users");
        await usersCol.updateOne(
          mongo.where.eq('email', existing.email),
          mongo.modify.set('isGoogleLinked', true).set('googleId', gId),
        );
      } catch (e) {
        print("MongoDB error linking google: $e");
      }

      await saveSession(
        email: existing.email,
        name: existing.name,
        token: 'google_jwt_${DateTime.now().millisecondsSinceEpoch}',
      );

      return {
        'status': 'linked_and_logged_in',
        'customer': updated,
        'message': 'Đã liên kết tài khoản Google và đăng nhập thành công!',
      };
    } else {
      // Chưa có tài khoản: Cần hoàn tất hồ sơ sau khi đăng nhập Google lần đầu
      _pendingEmail = cleanEmail;
      return {
        'status': 'needs_profile_setup',
        'email': cleanEmail,
        'name': name,
        'googleId': gId,
        'message': 'Đăng nhập Google lần đầu thành công! Vui lòng hoàn tất thông tin hồ sơ.',
      };
    }
  }

  // Hoàn tất hồ sơ sau khi đăng nhập Google lần đầu
  static Future<void> completeGoogleProfile({
    required String name,
    required String phone,
    required String password,
    String? googleId,
  }) async {
    if (_pendingEmail == null) return;
    final newCustomer = Customer(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: _pendingEmail!,
      password: password.isNotEmpty ? password : '123456',
      phone: phone,
      totalSpent: 0.0,
      totalOrders: 0,
      isActive: true,
      memberTier: 'Đồng',
      googleId: googleId ?? 'google_${_pendingEmail.hashCode.abs()}',
      isGoogleLinked: true,
    );

    await DataService.addCustomer(newCustomer);

    try {
      var usersCol = MongoDBService.getCollection("users");
      await usersCol.insertOne(newCustomer.toJson());
    } catch (e) {
      print("MongoDB error completeGoogleProfile: $e");
    }

    await saveSession(
      email: _pendingEmail!,
      name: name,
      token: 'google_jwt_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
