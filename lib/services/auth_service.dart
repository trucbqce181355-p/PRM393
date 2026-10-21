import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/customer.dart';
import 'storage_service.dart';
import 'auth_api_service.dart';
import 'email_otp_service.dart';
import 'session_storage.dart';

enum GoogleSignInStatus { waiting, verifying, linkRequired, success, error }

enum AuthSessionStatus { signedOut, restoring, authenticated, unavailable }

class AuthService {
  static final sessionStatus = ValueNotifier(AuthSessionStatus.signedOut);
  static final sessionInvalidations = ValueNotifier(0);
  static String? restoreError;
  static String? sessionNotice;
  static int _sessionGeneration = 0;
  static Future<void>? _restoration;
  static Future<void>? _refresh;
  static Future<void>? _signOut;
  static String? _revokedToken;
  static Future<void> _storageQueue = Future<void>.value();
  static Timer? _expiryTimer;
  static bool _isLoggedIn = false;
  static Customer? _backendCustomer;
  static String _backendRole = 'customer';
  static bool _backendHasPassword = false;
  static bool get hasPassword => isBackendSession && _backendHasPassword;
  static StreamSubscription<AuthState>? _googleSubscription;
  static Future<void>? _googleExchange;
  static bool _googleRequested = false;
  static int _googleGeneration = 0;
  static bool _googleLinkRequired = false;
  static bool get googleLinkRequired => _googleLinkRequired;
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

  static void _clearIdentity() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _backendCustomer = null;
    _backendHasPassword = false;
    _token = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _isLoggedIn = false;
    _backendRole = 'customer';
  }

  // Serialize reads/writes/deletes so a cancelled sign-in cannot overwrite a new one.
  static Future<T> _withStorage<T>(Future<T> Function() operation) {
    final result = _storageQueue.then((_) => operation());
    _storageQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  static DateTime _sessionExpiry(dynamic value) {
    final expiry = value is String ? DateTime.tryParse(value) : null;
    if (expiry == null) {
      throw StateError(
        'Server không trả về thời hạn phiên hợp lệ. Vui lòng kiểm tra phiên bản backend.',
      );
    }
    if (!expiry.isAfter(DateTime.now())) {
      throw BackendAuthException(
        401,
        'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.',
      );
    }
    return expiry;
  }

  static void _setIdentity(
    String token,
    Map<String, dynamic> profile,
    DateTime expiry,
  ) {
    _sessionExpiry(expiry.toIso8601String());
    final customer = Customer.fromJson(profile);
    if (customer.id.isEmpty || customer.email.isEmpty || !customer.isActive) {
      throw StateError('Server trả về hồ sơ không hợp lệ.');
    }
    _backendCustomer = customer;
    _token = token;
    _userName = customer.name;
    _userEmail = customer.email;
    _userPhone = customer.phone;
    _isLoggedIn = true;
    _backendRole = profile['role'] == 'admin' ? 'admin' : 'customer';
    _backendHasPassword = profile['hasPassword'] == true;
    restoreError = null;
    sessionNotice = null;
    _expiryTimer?.cancel();
    _expiryTimer = Timer(expiry.difference(DateTime.now()), () {
      unawaited(
        _invalidateSession(
          token,
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        ),
      );
    });
    sessionStatus.value = AuthSessionStatus.authenticated;
  }

  static Future<void> initSession() async {
    if (_signOut != null || _revokedToken != null) {
      if (_revokedToken != null) {
        sessionStatus.value = AuthSessionStatus.restoring;
      }
      try {
        await logout();
      } catch (_) {
        // Cleanup failure is already exposed through sessionStatus/restoreError.
      }
      return;
    }
    if (_restoration != null) return _restoration;
    final restoration = _restoreSession();
    _restoration = restoration;
    try {
      await restoration;
    } finally {
      if (identical(_restoration, restoration)) _restoration = null;
    }
  }

  static Future<void> _restoreSession() async {
    final generation = ++_sessionGeneration;
    _clearIdentity();
    restoreError = null;
    sessionNotice = null;
    sessionStatus.value = AuthSessionStatus.restoring;
    AuthApiService.onSessionRejected = (token, error) => _invalidateSession(
      token,
      error.status == 403
          ? error.message
          : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    );
    try {
      await StorageService.clearAuthSession();
      final token = await _withStorage(SessionStorage.read);
      if (generation != _sessionGeneration) return;
      if (token == null) {
        sessionStatus.value = AuthSessionStatus.signedOut;
        return;
      }
      if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
        await _discardStoredSession(generation);
        if (generation == _sessionGeneration) {
          sessionNotice = 'Phiên đã lưu không hợp lệ. Vui lòng đăng nhập lại.';
          sessionStatus.value = AuthSessionStatus.signedOut;
        }
        return;
      }
      try {
        final profile = await AuthApiService.request(
          'GET',
          '/session',
          token: token,
        );
        if (generation != _sessionGeneration) return;
        final expiry = _sessionExpiry(profile['expiresAt']);
        _setIdentity(token, profile, expiry);
      } on BackendAuthException catch (error) {
        if (generation != _sessionGeneration) return;
        if (error.status != 401 && error.status != 403) rethrow;
        await _discardStoredSession(generation);
        if (generation == _sessionGeneration) {
          sessionNotice = error.message;
          sessionStatus.value = AuthSessionStatus.signedOut;
        }
      }
    } catch (error) {
      if (generation != _sessionGeneration) return;
      restoreError = error is BackendAuthException
          ? error.message
          : 'Không thể đọc hoặc xác minh phiên đã lưu. Vui lòng thử lại.';
      sessionStatus.value = AuthSessionStatus.unavailable;
    }
  }

  static Future<void> _discardStoredSession(int generation) =>
      _withStorage(() async {
        if (generation == _sessionGeneration) await SessionStorage.delete();
      });

  static Future<void> _invalidateSession(String token, String message) async {
    if (_token != token) return;
    final generation = ++_sessionGeneration;
    cancelGoogleSignIn();
    _clearIdentity();
    sessionNotice = message;
    sessionStatus.value = AuthSessionStatus.signedOut;
    sessionInvalidations.value++;
    try {
      await _discardStoredSession(generation);
    } catch (_) {
      if (generation != _sessionGeneration) return;
      restoreError = 'Không thể xóa phiên đã lưu. Vui lòng thử lại.';
      sessionStatus.value = AuthSessionStatus.unavailable;
    }
  }

  static Future<void> refreshSession() async {
    if (!isBackendSession || _signOut != null) return;
    if (_refresh != null) return _refresh;
    final refresh = _refreshSession();
    _refresh = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_refresh, refresh)) _refresh = null;
    }
  }

  static Future<void> _refreshSession() async {
    final token = _token!;
    final generation = _sessionGeneration;
    try {
      final profile = await AuthApiService.request(
        'GET',
        '/session',
        token: token,
      );
      if (generation != _sessionGeneration || _token != token) return;
      _setIdentity(token, profile, _sessionExpiry(profile['expiresAt']));
    } on BackendAuthException catch (error) {
      if (error.status == 401 || error.status == 403) {
        await _invalidateSession(token, error.message);
      }
      // A temporary network failure does not destroy an accepted session.
    } catch (_) {
      // Keep the current identity/timer; the next resume can retry verification.
    }
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
            googleStatus.value = _googleLinkRequired
                ? GoogleSignInStatus.linkRequired
                : GoogleSignInStatus.error;
          },
        );
  }

  static Future<bool> loginWithGoogle() async {
    _requireSignOutFinished();
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Chưa cấu hình đăng nhập Google.');
    }
    listenGoogleAuth();
    _sessionGeneration++;
    _googleGeneration++;
    _googleRequested = true;
    _googleLinkRequired = false;
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
    _googleLinkRequired = false;
    googleError = null;
    googleStatus.value = GoogleSignInStatus.waiting;
  }

  static Future<void> retryGoogleSignIn() async {
    if (_googleLinkRequired) return;
    await _runGoogleExchange();
  }

  static Future<void> linkExistingGoogleAccount(String password) async {
    if (!_googleRequested || !_googleLinkRequired || password.isEmpty) return;
    await _runGoogleExchange(password: password);
  }

  static Future<void> _runGoogleExchange({String? password}) async {
    if (!_googleRequested) return;
    final generation = _googleGeneration;
    if (_googleExchange != null) {
      final previous = _googleExchange;
      await previous;
      if (_googleRequested &&
          generation == _googleGeneration &&
          googleStatus.value == GoogleSignInStatus.waiting) {
        if (identical(_googleExchange, previous)) _googleExchange = null;
        await _runGoogleExchange(password: password);
      }
      return;
    }
    final exchange = _exchangeGoogle(password: password);
    _googleExchange = exchange;
    try {
      await exchange;
    } finally {
      if (identical(_googleExchange, exchange)) _googleExchange = null;
    }
  }

  static Future<void> _exchangeGoogle({String? password}) async {
    final generation = _googleGeneration;
    final sessionGeneration = _sessionGeneration;
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
        body: password == null ? null : {'password': password},
      );
      if (!_googleRequested || generation != _googleGeneration) return;
      if (!await _acceptBackendSession(
        data,
        generation: sessionGeneration,
        googleGeneration: generation,
      )) {
        return;
      }
      _googleRequested = false;
      _googleLinkRequired = false;
      googleStatus.value = GoogleSignInStatus.success;
    } catch (error) {
      if (!_googleRequested || generation != _googleGeneration) return;
      googleError = error is StateError
          ? error.message
          : 'Không thể xác minh đăng nhập Google.';
      if (error is BackendAuthException &&
          error.code == 'account_link_required') {
        _googleLinkRequired = true;
      }
      googleStatus.value = _googleLinkRequired
          ? GoogleSignInStatus.linkRequired
          : GoogleSignInStatus.error;
    }
  }

  static Future<bool> verifyOTP(String otp) => EmailOtpService.verifyOtp(otp);

  static Future<void> logout() async {
    if (_signOut != null) return _signOut;
    final signOut = _performLogout();
    _signOut = signOut;
    try {
      await signOut;
    } finally {
      if (identical(_signOut, signOut)) _signOut = null;
    }
  }

  static Future<void> _performLogout() async {
    final token = _revokedToken ?? _token;
    final generation = ++_sessionGeneration;
    cancelGoogleSignIn();
    if (token != null && _revokedToken != token) {
      await AuthApiService.request('POST', '/logout', token: token);
      if (generation != _sessionGeneration) {
        throw StateError('Phiên đăng nhập đã thay đổi. Vui lòng thử lại.');
      }
      _revokedToken = token;
    }
    // A revoked identity must not remain usable if device cleanup fails.
    _clearIdentity();
    try {
      await _clearLocalSession(generation);
      _revokedToken = null;
    } catch (_) {
      if (generation == _sessionGeneration) {
        restoreError = 'Phiên đã kết thúc nhưng chưa thể xóa dữ liệu đăng nhập trên thiết bị. Vui lòng thử lại.';
        sessionStatus.value = AuthSessionStatus.unavailable;
        sessionInvalidations.value++;
      }
      throw StateError(
        restoreError ?? 'Không thể hoàn tất đăng xuất. Vui lòng thử lại.',
      );
    }
  }

  // Recovery for an unreadable/unverified saved credential, not an accepted login.
  static Future<void> discardSavedSession() async {
    if (isBackendSession || _revokedToken != null || _signOut != null) {
      return logout();
    }
    final generation = ++_sessionGeneration;
    cancelGoogleSignIn();
    await _clearLocalSession(generation);
  }

  static Future<void> _clearLocalSession(int generation) async {
    await _discardStoredSession(generation);
    if (generation != _sessionGeneration) {
      throw StateError('Phiên đăng nhập đã thay đổi. Vui lòng thử lại.');
    }
    if (_googleSubscription != null) {
      await Supabase.instance.client.auth
          .signOut(scope: SignOutScope.local)
          .timeout(const Duration(seconds: 15));
    }
    await StorageService.clearAuthSession();
    if (generation != _sessionGeneration) {
      throw StateError('Phiên đăng nhập đã thay đổi. Vui lòng thử lại.');
    }
    _clearIdentity();
    restoreError = null;
    sessionNotice = null;
    sessionStatus.value = AuthSessionStatus.signedOut;
    sessionInvalidations.value++;
  }

  static void _requireSignOutFinished() {
    if (_signOut != null || _revokedToken != null) {
      throw StateError('Vui lòng hoàn tất đăng xuất trước khi đăng nhập lại.');
    }
  }

  // ========================================================
  // --- CÁC HÀM TƯƠNG THÍCH CODE CŨ (ADMIN & EMAIL) ---
  // ========================================================
  /// Email/password authentication is authoritative on the backend.
  static Future<String> login(String email, String password) async {
    _requireSignOutFinished();
    cancelGoogleSignIn();
    final generation = ++_sessionGeneration;
    final data = await AuthApiService.request(
      'POST',
      '/login',
      body: {'email': email.trim(), 'password': password},
    );
    if (generation != _sessionGeneration) {
      throw StateError('Luồng đăng nhập đã thay đổi. Vui lòng thử lại.');
    }
    if (_googleSubscription != null &&
        Supabase.instance.client.auth.currentUser != null) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    }
    if (!await _acceptBackendSession(data, generation: generation)) {
      throw StateError('Luồng đăng nhập đã thay đổi. Vui lòng thử lại.');
    }
    return _backendRole;
  }

  static Future<bool> _acceptBackendSession(
    Map<String, dynamic> data, {
    required int generation,
    int? googleGeneration,
  }) async {
    final token = data['token'] as String;
    final profile = Map<String, dynamic>.from(data['customer'] as Map);
    final customer = Customer.fromJson(profile);
    final expiry = _sessionExpiry(data['expiresAt']);
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token) ||
        customer.id.isEmpty ||
        customer.email.isEmpty ||
        !customer.isActive) {
      throw StateError('Server trả về phiên đăng nhập không hợp lệ.');
    }
    bool stillRequested() =>
        generation == _sessionGeneration &&
        (googleGeneration == null ||
            (googleGeneration == _googleGeneration && _googleRequested));
    return _withStorage(() async {
      if (!stillRequested()) return false;
      try {
        await SessionStorage.write(token);
      } catch (_) {
        throw StateError(
          'Không thể lưu phiên an toàn trên thiết bị. Vui lòng thử lại.',
        );
      }
      if (!stillRequested()) {
        // Restore the accepted identity while holding the same storage queue.
        if (_token == null) {
          await SessionStorage.delete();
        } else {
          await SessionStorage.write(_token!);
        }
        return false;
      }
      _setIdentity(token, profile, expiry);
      return true;
    });
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
    await completeAuthenticatedProfile(
      name: name,
      phone: currentUser?.phone ?? '',
    );
  }

  static Future<void> completeAuthenticatedProfile({
    required String name,
    required String phone,
    String? password,
  }) async {
    if (!isBackendSession) throw StateError('Không tìm thấy phiên đăng nhập.');
    final sessionToken = _token;
    final customerId = _backendCustomer!.id;
    final email = _backendCustomer!.email;
    final body = <String, dynamic>{'name': name.trim(), 'phone': phone.trim()};
    if (password != null) body['password'] = password;
    final data = await AuthApiService.request(
      'PATCH',
      '/profile',
      token: sessionToken,
      body: body,
    );
    if (!isBackendSession ||
        _token != sessionToken ||
        currentUser?.id != customerId) {
      throw StateError('Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.');
    }
    final customer = Customer.fromJson(data);
    if (customer.id != customerId || customer.email != email) {
      throw StateError('Server trả về hồ sơ không hợp lệ.');
    }
    _backendCustomer = customer;
    _backendHasPassword = data['hasPassword'] == true;
    _userName = _backendCustomer!.name;
    _userEmail = _backendCustomer!.email;
    _userPhone = _backendCustomer!.phone;
  }
}
