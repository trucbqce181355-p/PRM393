import 'dart:async';

import 'package:flutter/services.dart';

import '../services/session_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';
import '../services/auth_api_service.dart';
import '../services/data_service.dart';

class AuthRepository {
  static const redirectUrl = 'com.example.traicay://login-callback';
  static final _events = StreamController<String?>.broadcast();
  static StreamSubscription<AuthState>? _subscription;
  static String? _token;
  static Customer? _customer;
  static Future<Customer?>? _googleExchange;
  static String? restoreError;
  static bool _localLogin = false;
  static bool _googlePending = false;
  static Timer? _expiryTimer;

  static void _armExpiry(String token, Map<String, dynamic> data) {
    _expiryTimer?.cancel();
    final expiresAt = DateTime.tryParse(data['expiresAt'] as String? ?? '');
    if (expiresAt == null)
      throw StateError('Máy chủ chưa trả về thời hạn phiên hợp lệ.');
    _expiryTimer = Timer(expiresAt.difference(DateTime.now()), () {
      unawaited(_expireSession(token));
    });
  }

  static Future<void> _expireSession(String token) async {
    if (_token != token) return;
    _expiryTimer?.cancel();
    _token = null;
    _customer = null;
    _googlePending = false;
    _localLogin = true;
    try {
      await SessionStorage.delete();
      if (_token != null) return;
      await _auth
          .signOut(scope: SignOutScope.local)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (_auth.currentSession != null)
        restoreError = 'Phiên đã hết hạn. Vui lòng khởi động lại ứng dụng.';
    } finally {
      _localLogin = false;
      _events.add(currentUserId);
    }
  }

  static GoTrueClient get _auth => Supabase.instance.client.auth;
  static Customer? get sessionCustomer => _customer;
  static String? get currentUserId => _customer?.id ?? _auth.currentUser?.id;
  static bool get hasCompletedProfile => _customer?.profileCompleted == true;
  static String? get userName =>
      _customer?.name.trim().isNotEmpty == true ? _customer!.name : null;
  static bool get isAwaitingGoogle =>
      _googlePending && _auth.currentSession != null;

  static void _listen() {
    _subscription ??= _auth.onAuthStateChange.listen(
      (event) {
        if (_localLogin) return;
        if (event.event == AuthChangeEvent.signedOut) {
          _events.add(_customer?.id);
        } else if (event.session != null) {
          if (event.event == AuthChangeEvent.signedIn) {
            _googlePending = true;
            _customer = null;
          }
          _events.add(_customer?.id ?? event.session!.user.id);
        }
      },
      onError: (Object error) {
        if (_token != null && _customer != null) {
          return;
        }
        restoreError = 'Không thể khôi phục phiên Google. Vui lòng thử lại.';
        _events.add(currentUserId);
      },
    );
  }

  static Stream<String?> get authStateChanges async* {
    _listen();
    yield currentUserId;
    yield* _events.stream;
  }

  static Future<void> restoreSession() async {
    _expiryTimer?.cancel();
    AuthApiService.onSessionRejected = (token, _) => _expireSession(token);
    _customer = null;
    _token = null;
    _localLogin = false;
    _googlePending = false;
    restoreError = null;
    final prefs = await SharedPreferences.getInstance();
    // ID-only sessions are deliberately never trusted after this upgrade.
    await prefs.remove('saved_session_user_id');
    String? token;
    try {
      token = await SessionStorage.read();
    } on PlatformException {
      restoreError = 'Không truy cập được kho lưu phiên của hệ điều hành. Vui lòng thử lại.';
      return;
    }
    if (token == null) return;
    _token = token;
    try {
      final data = await AuthApiService.request(
        'GET',
        '/session',
        token: token,
      );
      _token = token;
      _customer = Customer.fromJson(data);
      _armExpiry(token, data);
      _localLogin = _customer?.sessionProvider != 'google';
      await DataService.cacheCustomer(_customer!);
    } on BackendAuthException catch (error) {
      if (error.status == 401 || error.status == 403) {
        await SessionStorage.delete();
        _token = null;
      } else {
        restoreError = error.message;
      }
    }
    _events.add(currentUserId);
  }

  static Future<Customer> acceptSession(
    Map<String, dynamic> data, {
    bool local = true,
  }) async {
    final token = data['token'] as String;
    final customer = Customer.fromJson(
      Map<String, dynamic>.from(data['customer'] as Map),
    );
    // Do not mark the UI logged in if secure storage fails.
    await SessionStorage.write(token);
    _token = token;
    _customer = customer;
    _armExpiry(token, data);
    _localLogin = local;
    if (local) _googlePending = false;
    restoreError = null;
    await DataService.cacheCustomer(customer);
    _events.add(customer.id);
    return customer;
  }

  static Future<String> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final data = await AuthApiService.request(
      'POST',
      '/login',
      body: {'email': email.trim(), 'password': password},
    );
    final customer = await acceptSession(data);
    // A local login takes precedence; remove any stale OAuth identity.
    if (_auth.currentUser != null) {
      await _auth.signOut(scope: SignOutScope.local);
    }
    return customer.role;
  }

  static Future<bool> signInWithGoogle() async {
    _localLogin = false;
    _googlePending = true;
    // Only clear the old application session after Google completes successfully.
    return _auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirectUrl);
  }

  static Future<Customer?> _exchangeGoogle() async {
    final googleToken = _auth.currentSession?.accessToken;
    if (googleToken == null) return null;
    final data = await AuthApiService.request(
      'POST',
      '/google',
      token: googleToken,
    );
    final customer = await acceptSession(data, local: false);
    _googlePending = false;
    return customer;
  }

  static Future<Customer> linkExistingGoogleAccount(String password) async {
    final token = _auth.currentSession?.accessToken;
    if (token == null) {
      throw StateError('Phiên Google đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final data = await AuthApiService.request(
      'POST',
      '/google',
      token: token,
      body: {'password': password},
    );
    final customer = await acceptSession(data, local: false);
    _googlePending = false;
    return customer;
  }

  static Future<Customer?> fetchCustomerProfile() async {
    if (!_googlePending && _token != null && _customer != null) {
      final data = await AuthApiService.request(
        'GET',
        '/session',
        token: _token,
      );
      _customer = Customer.fromJson(data);
      await DataService.cacheCustomer(_customer!);
      return _customer;
    }
    if (_auth.currentUser == null) return null;
    // A single OAuth callback can rebuild AuthGate more than once.
    _googleExchange ??= _exchangeGoogle();
    try {
      return await _googleExchange;
    } finally {
      _googleExchange = null;
    }
  }

  static Future<bool> saveCustomerProfile({
    required String name,
    required String phone,
    String? password,
  }) async {
    if (_token == null) await fetchCustomerProfile();
    if (_token == null) return false;
    final data = await AuthApiService.request(
      'PATCH',
      '/profile',
      token: _token,
      body: {'name': name.trim(), 'phone': phone.trim(), 'password': ?password},
    );
    _customer = Customer.fromJson(data);
    await DataService.cacheCustomer(_customer!);
    _events.add(_customer!.id);
    return true;
  }

  static Future<Customer> setCustomerStatus(String id, bool isActive) async {
    final data = await AuthApiService.request(
      'PATCH',
      '/customers/$id/status',
      token: _token,
      body: {'isActive': isActive},
    );
    final customer = Customer.fromJson(data);
    await DataService.cacheCustomer(customer);
    return customer;
  }

  static Future<void> refreshCustomers() async {
    final data = await AuthApiService.request(
      'GET',
      '/customers',
      token: _token,
    );
    DataService.customers = (data['customers'] as List)
        .map(
          (item) => Customer.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<void> signOut() async {
    final token = _token;
    // Require server revocation before reporting a completed logout.
    if (token != null) {
      try {
        await AuthApiService.request('POST', '/logout', token: token);
      } on BackendAuthException catch (error) {
        if (error.status != 401 && error.status != 403) rethrow;
      }
    }
    await SessionStorage.delete();
    _expiryTimer?.cancel();
    _token = null;
    _customer = null;
    _localLogin = false;
    _googlePending = false;
    restoreError = null;
    await _auth.signOut(scope: SignOutScope.local);
    _events.add(null);
  }

  static Future<bool> changeAdminPassword(
    String oldPassword,
    String newPassword,
  ) async {
    if (_token == null || _customer?.role != 'admin')
      throw StateError('Không có quyền quản trị.');
    try {
      await AuthApiService.request(
        'PATCH',
        '/admin/password',
        token: _token,
        body: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      return true;
    } on BackendAuthException catch (error) {
      if (error.code == 'wrong_password') return false;
      rethrow;
    }
  }
}
