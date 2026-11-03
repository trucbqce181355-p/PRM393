// Author: Chih An (GitHub: ChangChinAn)
// UC06: OAuth Google qua Supabase, sau đó đổi token lấy phiên của ứng dụng.
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

  Future<Map<String, dynamic>> _exchange(String accessToken) async {
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/google'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'}, body: '{}')
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
    if (_pending != null) throw const LoginException('Đăng nhập Google đang được xử lý.', code: 'google_in_progress');
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
      unawaited(_exchange(event.session!.accessToken).then<void>((data) {
        if (_disposed || !identical(_pending, operation) || operation.isCompleted) return;
        try { operation.complete(_loginService.acceptSession(data)); }
        catch (error, stack) { fail(error, stack); }
      }, onError: fail));
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

  void cancel() {
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
