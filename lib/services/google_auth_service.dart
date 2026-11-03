// Author: Chih An (GitHub: ChangChinAn)
// UC06–UC07: OAuth Google và xác nhận liên kết tài khoản email cùng địa chỉ.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_service.dart';
import 'otp_request_service.dart';

class GoogleAuthService {
  GoogleAuthService({http.Client? client, LoginService? loginService, String? baseUrl})
      : _client = client ?? http.Client(), _ownsClient = client == null,
        _loginService = loginService ?? LoginService(), _ownsLoginService = loginService == null,
        _baseUrl = baseUrl ?? OtpRequestService.defaultBaseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final LoginService _loginService;
  final bool _ownsLoginService;
  final String _baseUrl;
  StreamSubscription<AuthState>? _subscription;
  Completer<LoginResult>? _pending;
  bool _disposed = false;
  String? _linkAccessToken;
  String? _linkIdentityId;
  String? _linkEmail;
  int _linkGeneration = 0;
  bool _linking = false;
  bool get requiresAccountLink => _linkAccessToken != null && _linkIdentityId != null;
  String? get pendingLinkEmail => _linkEmail;
  static bool _ready = false;
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _redirectUrl = String.fromEnvironment('GOOGLE_AUTH_REDIRECT_URL',
    defaultValue: 'com.example.traicay://login-callback');

  static Future<void> initialize() async {
    if (_ready || _url.isEmpty || (_publishableKey.isEmpty && _anonKey.isEmpty)) return;
    try {
      await Supabase.initialize(url: _url,
        publishableKey: _publishableKey.isNotEmpty ? _publishableKey : _anonKey,
        authOptions: const FlutterAuthClientOptions(localStorage: EmptyLocalStorage(), autoRefreshToken: false));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<Map<String, dynamic>> _exchange(String accessToken, {String? password}) async {
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/google'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({if (password != null) 'password': password}))
        .timeout(const Duration(seconds: 25));
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true) {
        throw LoginException(result['message'] as String? ?? 'Không thể đăng nhập Google.',
          code: result['code'] as String? ?? 'google_error');
      }
      return Map<String, dynamic>.from(result['data'] as Map);
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể kết nối dịch vụ đăng nhập Google.', code: 'google_connection_error');
    }
  }

  Future<void> _launch(GoTrueClient auth, Completer<LoginResult> operation) async {
    await auth.signOut(scope: SignOutScope.local).timeout(const Duration(seconds: 10));
    if (_disposed || !identical(_pending, operation) || operation.isCompleted) return;
    final launched = await auth.signInWithOAuth(OAuthProvider.google, redirectTo: _redirectUrl,
      queryParams: {'prompt': 'select_account'});
    if (!launched) throw const LoginException('Không thể mở trang đăng nhập Google.', code: 'google_launch_failed');
  }

  Future<LoginResult> signIn() async {
    if (_disposed) throw const LoginException('Màn hình đăng nhập đã đóng.', code: 'google_cancelled');
    if (!_ready) throw const LoginException('Đăng nhập Google chưa khả dụng. Vui lòng dùng email/mật khẩu hoặc thử lại sau.', code: 'google_not_configured');
    if (_pending != null || _linking) throw const LoginException('Đăng nhập Google đang được xử lý.', code: 'google_in_progress');
    clearPendingLink();
    final operation = Completer<LoginResult>();
    _pending = operation;
    bool exchanging = false;
    void fail(Object error, StackTrace stack) {
      if (_disposed || !identical(_pending, operation) || operation.isCompleted) return;
      operation.completeError(error is LoginException ? error
        : const LoginException('Không thể hoàn tất đăng nhập Google. Vui lòng thử lại.', code: 'google_failed'), stack);
    }
    final auth = Supabase.instance.client.auth;
    _subscription = auth.onAuthStateChange.listen((event) {
      if (_disposed || !identical(_pending, operation) || operation.isCompleted || exchanging ||
          event.event != AuthChangeEvent.signedIn || event.session == null) return;
      exchanging = true;
      final providerSession = event.session!;
      unawaited(_exchange(providerSession.accessToken).then<void>((data) {
        if (_disposed || !identical(_pending, operation) || operation.isCompleted) return;
        try { operation.complete(_loginService.acceptSession(data)); }
        catch (error, stack) { fail(error, stack); }
      }, onError: (Object error, StackTrace stack) {
        if (!_disposed && identical(_pending, operation) && !operation.isCompleted &&
            error is LoginException && error.code == 'account_link_required') {
          _linkAccessToken = providerSession.accessToken;
          _linkIdentityId = providerSession.user.id;
          _linkEmail = providerSession.user.email;
          _linkGeneration++;
        }
        fail(error, stack);
      }));
    }, onError: fail);
    final waiting = operation.future.timeout(const Duration(minutes: 3), onTimeout: () {
      throw const LoginException('Đăng nhập Google đã hết thời gian chờ. Vui lòng thử lại.', code: 'google_timeout');
    });
    unawaited(_launch(auth, operation).then<void>((_) {}, onError: fail));
    try {
      return await waiting;
    } finally {
      if (identical(_pending, operation)) _pending = null;
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  Future<LoginResult> linkExistingAccount(String password) async {
    if (_disposed || !requiresAccountLink) {
      throw const LoginException('Vui lòng đăng nhập Google lại để liên kết.', code: 'google_session_changed');
    }
    if (_pending != null || _linking) throw const LoginException('Liên kết đang được xử lý.', code: 'google_in_progress');
    final token = _linkAccessToken!;
    final identityId = _linkIdentityId;
    final generation = _linkGeneration;
    final providerSession = Supabase.instance.client.auth.currentSession;
    if (providerSession == null || providerSession.user.id != identityId || providerSession.accessToken != token) {
      clearPendingLink();
      throw const LoginException('Phiên Google đã thay đổi. Vui lòng đăng nhập lại.', code: 'google_session_changed');
    }
    _linking = true;
    try {
      final data = await _exchange(token, password: password);
      if (_disposed || generation != _linkGeneration || _linkAccessToken != token) {
        throw const LoginException('Liên kết Google đã bị hủy.', code: 'google_cancelled');
      }
      final current = Supabase.instance.client.auth.currentSession;
      if (current == null || current.user.id != identityId || current.accessToken != token) {
        clearPendingLink();
        throw const LoginException('Phiên Google đã thay đổi. Vui lòng đăng nhập lại.', code: 'google_session_changed');
      }
      final result = _loginService.acceptSession(data);
      clearPendingLink();
      return result;
    } on LoginException catch (error) {
      if (['invalid_google_token', 'account_locked', 'account_changed', 'google_already_linked', 'google_link_denied'].contains(error.code)) {
        clearPendingLink();
      }
      rethrow;
    } finally {
      _linking = false;
    }
  }

  void clearPendingLink() {
    _linkGeneration++;
    _linkAccessToken = null; _linkIdentityId = null; _linkEmail = null;
  }

  void cancel() {
    clearPendingLink();
    final operation = _pending;
    if (operation != null && !operation.isCompleted) {
      operation.completeError(const LoginException('Đã hủy đăng nhập Google.', code: 'google_cancelled'));
    }
  }
  void dispose() {
    cancel(); _disposed = true;
    unawaited(_subscription?.cancel());
    if (_ownsClient) _client.close();
    if (_ownsLoginService) _loginService.dispose();
  }
}
