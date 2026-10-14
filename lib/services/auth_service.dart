import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/customer.dart';
import 'storage_service.dart';
import 'auth_api_service.dart';
import 'email_otp_service.dart';

enum GoogleSignInStatus { waiting, verifying, success, error }

class AuthService {
  static bool _isLoggedIn = false;
  static Customer? _backendCustomer;
  static String _backendRole = 'customer';
  static StreamSubscription<AuthState>? _googleSubscription;
  static Future<void>? _googleExchange;
  static bool _googleRequested = false;
  static int _googleGeneration = 0;
  static String? googleError;
  static final googleStatus = ValueNotifier(GoogleSignInStatus.waiting);
  static String get role => isBackendSession ? _backendRole : 'customer';
  static bool get hasCompletedProfile =>
      _backendCustomer?.name.trim().isNotEmpty == true &&
      _backendCustomer?.phone.trim().isNotEmpty == true;
  static String? _token;
  static String? _userName;
  static String? _userEmail;
  static String? _userPhone;

  static bool get isLoggedIn => _isLoggedIn;
  static bool get isBackendSession =>
      _backendCustomer != null &&
      RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(_token ?? '');
  static String? get token => _token;
  static String? get userName =>
      _userName?.trim().isNotEmpty == true ? _userName : null;
  static String? get userEmail => _userEmail;
  static String? get userPhone => _userPhone;

  static Customer? get currentUser =>
      _isLoggedIn && isBackendSession ? _backendCustomer : null;

  // Current backend sessions are memory-only; secure restoration is added in UC 8.
  static Future<void> initSession() async {
    await StorageService.clearAuthSession();
    _backendCustomer = null;
    _token = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _isLoggedIn = false;
  }

  static void listenGoogleAuth() {
    _googleSubscription ??= Supabase.instance.client.auth.onAuthStateChange
        .listen(
          (event) {
            if (_googleRequested &&
                event.event == AuthChangeEvent.signedIn &&
                event.session != null) {
              unawaited(retryGoogleSignIn());
            }
          },
          onError: (Object error) {
            if (!_googleRequested) return;
            googleError =
                'Không thể hoàn tất đăng nhập Google. Vui lòng thử lại.';
            googleStatus.value = GoogleSignInStatus.error;
          },
        );
  }

  static Future<bool> loginWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Chưa cấu hình đăng nhập Google.');
    }
    listenGoogleAuth();
    _googleGeneration++;
    _googleRequested = true;
    googleError = null;
    googleStatus.value = GoogleSignInStatus.waiting;
    try {
      final opened = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.traicay://login-callback',
        queryParams: const {'prompt': 'select_account'},
      );
      if (!opened) cancelGoogleSignIn();
      return opened;
    } catch (_) {
      cancelGoogleSignIn();
      rethrow;
    }
  }

  static void cancelGoogleSignIn() {
    _googleRequested = false;
    _googleGeneration++;
    googleError = null;
    googleStatus.value = GoogleSignInStatus.waiting;
  }

  static Future<void> retryGoogleSignIn() async {
    if (!_googleRequested) return;
    if (_googleExchange != null) {
      final previous = _googleExchange;
      await previous;
      if (_googleRequested &&
          googleStatus.value == GoogleSignInStatus.waiting) {
        if (identical(_googleExchange, previous)) _googleExchange = null;
        await retryGoogleSignIn();
      }
      return;
    }
    final exchange = _exchangeGoogle();
    _googleExchange = exchange;
    try {
      await exchange;
    } finally {
      if (identical(_googleExchange, exchange)) _googleExchange = null;
    }
  }

  static Future<void> _exchangeGoogle() async {
    final generation = _googleGeneration;
    googleError = null;
    googleStatus.value = GoogleSignInStatus.verifying;
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw StateError('Phiên Google đã hết hạn. Vui lòng đăng nhập lại.');
      }
      final data = await AuthApiService.request(
        'POST',
        '/google',
        token: token,
      );
      if (!_googleRequested || generation != _googleGeneration) return;
      if (!await _acceptBackendSession(data, googleGeneration: generation)) {
        return;
      }
      _googleRequested = false;
      googleStatus.value = GoogleSignInStatus.success;
    } catch (error) {
      if (!_googleRequested || generation != _googleGeneration) return;
      googleError = error is StateError
          ? error.message
          : 'Không thể xác minh đăng nhập Google.';
      googleStatus.value = GoogleSignInStatus.error;
    }
  }

  static Future<bool> verifyOTP(String otp) => EmailOtpService.verifyOtp(otp);

  static Future<void> logout() async {
    cancelGoogleSignIn();
    _backendCustomer = null;
    _isLoggedIn = false;
    _token = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    await StorageService.clearAuthSession();
    if (_googleSubscription != null) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    }
  }

  // ========================================================
  // --- CÁC HÀM TƯƠNG THÍCH CODE CŨ (ADMIN & EMAIL) ---
  // ========================================================
  /// Email/password authentication is authoritative on the backend.
  static Future<String> login(String email, String password) async {
    cancelGoogleSignIn();
    final data = await AuthApiService.request(
      'POST',
      '/login',
      body: {'email': email.trim(), 'password': password},
    );
    if (_googleSubscription != null &&
        Supabase.instance.client.auth.currentUser != null) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    }
    await _acceptBackendSession(data);
    return _backendRole;
  }

  static Future<bool> _acceptBackendSession(
    Map<String, dynamic> data, {
    int? googleGeneration,
  }) async {
    final token = data['token'] as String;
    final profile = Map<String, dynamic>.from(data['customer'] as Map);
    final customer = Customer.fromJson(profile);
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      throw StateError('Server trả về phiên đăng nhập không hợp lệ.');
    }
    // Remove an older legacy identity. Backend sessions stay in memory until UC 8.
    await StorageService.clearAuthSession();
    if (googleGeneration != null &&
        (googleGeneration != _googleGeneration || !_googleRequested)) {
      return false;
    }
    _backendCustomer = customer;
    _token = token;
    _userName = customer.name;
    _userEmail = customer.email;
    _userPhone = customer.phone;
    _isLoggedIn = true;
    _backendRole = profile['role'] == 'admin' ? 'admin' : 'customer';
    return true;
  }

  // Compatibility for existing legacy callers; SMTP credentials stay on the server.
  static Future<String> loginWithEmail(String targetEmail) async {
    try {
      await EmailOtpService.sendOtp(targetEmail);
      return '';
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể gửi OTP. Vui lòng thử lại.';
    }
  }

  // Compatibility for member UI; profile updates require the protected API.
  static Future<void> saveProfile(String name, String email) async {
    if (!isBackendSession) throw StateError('Không tìm thấy phiên đăng nhập.');
    if (email.trim().toLowerCase() != currentUser?.email.trim().toLowerCase()) {
      throw StateError('Không thay đổi email trong bước cập nhật hồ sơ.');
    }
    final data = await AuthApiService.request(
      'PATCH',
      '/profile',
      token: _token,
      body: {'name': name.trim(), 'phone': currentUser?.phone ?? ''},
    );
    _backendCustomer = Customer.fromJson(data);
    _userName = _backendCustomer!.name;
    _userEmail = _backendCustomer!.email;
    _userPhone = _backendCustomer!.phone;
  }
}
