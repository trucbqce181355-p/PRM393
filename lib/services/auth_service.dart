import 'dart:math';
import '../models/customer.dart';
import 'data_service.dart';
import 'mongodb_service.dart';
import 'storage_service.dart';
import 'auth_api_service.dart';
import 'email_otp_service.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static Customer? _backendCustomer;
  static String? _token;
  static String? _userName;
  static String? _userEmail;
  static String? _userPhone;
  static String? _expectedOtp;
  static String? _pendingPhone;
  static String? _pendingEmail;

  static bool get isLoggedIn => _isLoggedIn;
  static bool get isBackendSession => _backendCustomer != null &&
      RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(_token ?? '');
  static String? get token => _token;
  static String? get userName => _userName;
  static String? get userEmail => _userEmail;
  static String? get userPhone => _userPhone;
  static String? get pendingPhone => _pendingPhone;
  static String? get pendingEmail => _pendingEmail;

  static Customer? get currentUser {
    if (_isLoggedIn && isBackendSession) return _backendCustomer;
    if (!_isLoggedIn) return null;
    try {
      if (_userEmail != null && _userEmail!.isNotEmpty) {
        return DataService.customers.firstWhere((c) => c.email == _userEmail);
      }
      if (_userPhone != null && _userPhone!.isNotEmpty) {
        return DataService.customers.firstWhere((c) => c.phone == _userPhone);
      }
    } catch (_) {}
    return null;
  }

  // ========================================================
  // --- BƯỚC 1: KHỞI TẠO & PHỤC HỒI PHIÊN TỪ LOCAL STORAGE ---
  // ========================================================
  static Future<void> initSession() async {
    _backendCustomer = null;
    final localToken = StorageService.getAuthToken();
    final localSession = StorageService.getUserSession();

    if (localToken != null && localToken.isNotEmpty && localSession != null) {
      _token = localToken;
      _userName = localSession['name'] as String?;
      _userEmail = localSession['email'] as String?;
      _userPhone = localSession['phone'] as String?;
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
      _token = null;
      _userName = null;
      _userEmail = null;
      _userPhone = null;
    }
  }

  // ========================================================
  // --- BƯỚC 2A: ĐĂNG NHẬP BẰNG GOOGLE ---
  // ========================================================
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 900));

    // Mock thông tin tài khoản Google được chọn
    const googleEmail = 'huytg.fpt@gmail.com';
    const googleName = 'Trần Gia Huy';

    // Kiểm tra xem User đã tồn tại trong hệ thống chưa
    Customer? existingCustomer;
    try {
      existingCustomer = DataService.customers.firstWhere((c) => c.email == googleEmail);
    } catch (_) {
      existingCustomer = null;
    }

    if (existingCustomer != null) {
      // Đã có tài khoản -> Đăng nhập & lưu token local ngay
      _token = 'jwt_google_${DateTime.now().millisecondsSinceEpoch}';
      _userName = existingCustomer.name;
      _userEmail = existingCustomer.email;
      _userPhone = existingCustomer.phone;
      _isLoggedIn = true;

      await StorageService.saveAuthToken(_token!);
      await StorageService.saveUserSession({
        'id': existingCustomer.id,
        'name': existingCustomer.name,
        'email': existingCustomer.email,
        'phone': existingCustomer.phone,
        'loginMethod': 'google',
      });

      return {
        'isNewUser': false,
        'name': existingCustomer.name,
        'email': existingCustomer.email,
        'phone': existingCustomer.phone,
      };
    } else {
      // User mới -> cần điền/xác nhận thông tin cá nhân
      _pendingEmail = googleEmail;
      return {
        'isNewUser': true,
        'name': googleName,
        'email': googleEmail,
        'phone': '',
      };
    }
  }

  // ========================================================
  // --- BƯỚC 2B: ĐĂNG NHẬP BẰNG SỐ ĐIỆN THOẠI (GỬI OTP) ---
  // ========================================================
  static Future<String> sendPhoneOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 600));

    _pendingPhone = phone;
    final random = Random();
    // Tạo mã OTP 6 chữ số ngẫu nhiên
    _expectedOtp = (100000 + random.nextInt(900000)).toString();

    return _expectedOtp!;
  }

  // ========================================================
  // --- BƯỚC 3: XÁC MINH OTP ---
  // ========================================================
  static Future<bool> verifyOTP(String otp) => verifyOtp(otp);

  static Future<bool> verifyOtp(String enteredOtp) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Cho phép mã ngẫu nhiên vừa tạo hoặc mã fallback tiện lợi '123456'
    final isValid = (enteredOtp == _expectedOtp) || (enteredOtp == '123456');
    return isValid;
  }

  // ========================================================
  // --- BƯỚC 4 & 5: ĐIỀN HỒ SƠ & LƯU TOKEN LOCAL ---
  // ========================================================
  static Future<void> completeProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final effectivePhone = phone ?? _pendingPhone ?? '';
    final newId = 'c${DateTime.now().millisecondsSinceEpoch}';

    final newCustomer = Customer(
      id: newId,
      name: name,
      email: email,
      phone: effectivePhone,
      totalSpent: 0.0,
      totalOrders: 0,
      isActive: true,
      memberTier: 'Đồng',
    );

    // Lưu vào DataService (Hive local database)
    await DataService.addCustomer(newCustomer);

    // Lưu vào MongoDB Cloud
    try {
      var usersCollection = MongoDBService.getCollection("users");
      await usersCollection.insertOne({
        "id": newId,
        "name": name,
        "email": email,
        "phone": effectivePhone,
        "password": "none",
        "role": "customer",
        "authMethod": effectivePhone.isNotEmpty ? "phone_otp" : "google",
        "created_at": DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // BƯỚC 5: Sinh Token JWT và Lưu phiên xuống SharedPreferences
    _token = 'jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    _userName = name;
    _userEmail = email;
    _userPhone = effectivePhone;
    _isLoggedIn = true;

    await StorageService.saveAuthToken(_token!);
    await StorageService.saveUserSession({
      'id': newId,
      'name': name,
      'email': email,
      'phone': effectivePhone,
    });
  }

  // ========================================================
  // --- ĐĂNG XUẤT (XÓA TOKEN & SESSION) ---
  // ========================================================
  static Future<void> logout() async {
    _backendCustomer = null;
    _isLoggedIn = false;
    _token = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _pendingPhone = null;
    _pendingEmail = null;
    _expectedOtp = null;
    await StorageService.clearAuthSession();
  }

  // ========================================================
  // --- CÁC HÀM TƯƠNG THÍCH CODE CŨ (ADMIN & EMAIL) ---
  // ========================================================
  /// Email/password authentication is authoritative on the backend.
  static Future<String> login(String email, String password) async {
    final data = await AuthApiService.request('POST', '/login',
      body: {'email': email.trim(), 'password': password});
    final token = data['token'] as String;
    final profile = Map<String, dynamic>.from(data['customer'] as Map);
    final customer = Customer.fromJson(profile);
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      throw StateError('Server trả về phiên đăng nhập không hợp lệ.');
    }
    // Remove an older legacy identity. Backend sessions stay in memory until UC 8.
    await StorageService.clearAuthSession();
    _backendCustomer = customer;
    _token = token;
    _userName = customer.name;
    _userEmail = customer.email;
    _userPhone = customer.phone;
    _pendingPhone = null;
    _pendingEmail = null;
    _expectedOtp = null;
    _isLoggedIn = true;
    return profile['role'] == 'admin' ? 'admin' : 'customer';
  }

  // Compatibility for existing legacy callers; SMTP credentials stay on the server.
  static Future<String> loginWithEmail(String targetEmail) async {
    try {
      await EmailOtpService.sendOtp(targetEmail);
      _pendingEmail = targetEmail.trim().toLowerCase();
      return '';
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể gửi OTP. Vui lòng thử lại.';
    }
  }

  static Future<void> registerCustomer(String name, String phone, String password) async {
    await completeProfile(name: name, email: _pendingEmail ?? '$phone@fruitopia.vn', phone: phone);
  }

  static Future<void> saveProfile(String name, String email) async {
    await completeProfile(name: name, email: email);
  }
}
