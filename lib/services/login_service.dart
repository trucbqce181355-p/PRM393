// Author: Chih An (GitHub: ChangChinAn)
// UC05–UC12: Đăng nhập, quản lý phiên và xem/chỉnh sửa hồ sơ đã xác thực.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'otp_request_service.dart';
import 'session_storage.dart';
import '../models/customer_profile.dart';

class LoginException implements Exception {
  const LoginException(this.message, {required this.code});
  final String message;
  final String code;
}

class LoginCustomer {
  const LoginCustomer({required this.id, required this.name, required this.email, required this.role,
    this.profileCompleted = true, this.hasPassword = true, this.sessionProvider = 'password', this.phone = ''});
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final bool profileCompleted;
  final bool hasPassword;
  final String sessionProvider;
}

class LoginResult {
  const LoginResult({required this.token, required this.expiresAt, required this.customer,
    this.linkedExistingAccount = false});
  final String token;
  final DateTime expiresAt;
  final LoginCustomer customer;
  final bool linkedExistingAccount;
}

class LoginService {
  LoginService({http.Client? client, String? baseUrl, SessionStorage? storage})
      : _client = client ?? http.Client(), _ownsClient = client == null,
        _storage = storage ?? SessionStorage(),
        _baseUrl = baseUrl ?? OtpRequestService.defaultBaseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  final SessionStorage _storage;
  bool _disposed = false;
  static LoginResult? _currentSession;
  static LoginResult? get currentSession => _currentSession;
  static final _events = StreamController<LoginResult?>.broadcast();
  static Stream<LoginResult?> get sessionEvents => _events.stream;
  static Timer? _expiryTimer;
  static int _revision = 0;
  static Future<void> _storageQueue = Future<void>.value();
  static String? sessionMessage;

  Future<T> _serializeStorage<T>(Future<T> Function() operation) {
    final next = _storageQueue.then((_) => operation());
    _storageQueue = next.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return next;
  }

  Future<void> invalidateSession(String token, {String? message}) async {
    if (_currentSession != null && _currentSession!.token != token) return;
    _revision++;
    _expiryTimer?.cancel();
    _currentSession = null;
    sessionMessage = message ?? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    _events.add(null);
    try {
      await _serializeStorage(() async {
        if (await _storage.read() == token) await _storage.delete();
      });
    } catch (_) {
      sessionMessage = 'Phiên không còn hợp lệ nhưng chưa xóa được token khỏi kho bảo mật. Vui lòng thử lại.';
      throw LoginException(sessionMessage!, code: 'session_storage_error');
    }
  }

  Future<LoginResult> acceptSession(Map<String, dynamic> data, {bool Function()? isActive}) async {
    final revision = _revision;
    final customer = Map<String, dynamic>.from(data['customer'] as Map);
    final token = data['token'] as String;
    final expiresAt = DateTime.parse(data['expiresAt'] as String);
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token) || !expiresAt.isAfter(DateTime.now())) {
      throw const LoginException('Phiên đăng nhập không hợp lệ hoặc đã hết hạn.', code: 'session_expired');
    }
    final session = LoginResult(token: token, expiresAt: expiresAt,
      linkedExistingAccount: data['linkedExistingAccount'] == true,
      customer: LoginCustomer(id: customer['id'] as String, name: customer['name'] as String,
        email: customer['email'] as String, role: customer['role'] as String,
        phone: customer['phone'] as String? ?? '',
        profileCompleted: customer['profileCompleted'] as bool? ?? true,
        hasPassword: customer['hasPassword'] as bool? ?? true,
        sessionProvider: customer['sessionProvider'] as String? ?? 'password'));
    bool active() => !_disposed && revision == _revision && (isActive?.call() ?? true);
    await _serializeStorage(() async {
      if (!active()) throw const LoginException('Phiên đăng nhập đã thay đổi.', code: 'session_cancelled');
      try { await _storage.write(token); }
      catch (_) { throw const LoginException('Không lưu được phiên vào kho bảo mật. Vui lòng thử lại.', code: 'session_storage_error'); }
      if (!active() || !expiresAt.isAfter(DateTime.now())) {
        await _storage.delete();
        throw const LoginException('Phiên đăng nhập đã thay đổi hoặc hết hạn.', code: 'session_cancelled');
      }
      _currentSession = session;
      sessionMessage = null;
      _expiryTimer?.cancel();
      _expiryTimer = Timer(expiresAt.difference(DateTime.now()), () {
        unawaited(invalidateSession(token).catchError((Object error) {
          _events.add(null);
        }));
      });
      _events.add(session);
    });
    return session;
  }

  Future<LoginResult?> restoreSession() async {
    final revision = _revision;
    String? token;
    try { token = await _serializeStorage(() => _storage.read()); }
    catch (_) { throw const LoginException('Không đọc được kho lưu phiên bảo mật. Vui lòng thử lại.', code: 'session_storage_error'); }
    if (_disposed || revision != _revision) return _currentSession;
    if (token == null) return null;
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      await invalidateSession(token);
      return null;
    }
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/session'),
        headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 25));
      if (_disposed || revision != _revision) return _currentSession;
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode == 401 || response.statusCode == 403) {
        await invalidateSession(token, message: result['message'] as String?);
        return null;
      }
      if (response.statusCode != 200 || result['success'] != true) {
        throw const LoginException('Chưa thể xác thực phiên với máy chủ. Vui lòng thử lại.', code: 'session_restore_error');
      }
      final data = Map<String, dynamic>.from(result['data'] as Map);
      if (data['token'] != token) throw const FormatException('Session token mismatch');
      return await acceptSession(data, isActive: () => revision == _revision);
    } on LoginException catch (error) {
      if (error.code == 'session_expired') {
        await invalidateSession(token);
        return null;
      }
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể kết nối để khôi phục phiên. Vui lòng thử lại.', code: 'session_restore_error');
    }
  }

  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'password': password}))
        .timeout(const Duration(seconds: 25));
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true) {
        throw LoginException(result['message'] as String? ?? 'Đăng nhập không thành công.',
          code: result['code'] as String? ?? 'server_error');
      }
      final data = Map<String, dynamic>.from(result['data'] as Map);
      return await acceptSession(data);
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể kết nối dịch vụ đăng nhập. Vui lòng thử lại.', code: 'connection_error');
    }
  }
  Future<LoginResult> completeGoogleProfile(LoginResult session, {
    required String name, required String phone, String? password,
  }) async {
    if (!identical(_currentSession, session) || !session.expiresAt.isAfter(DateTime.now())) {
      if (identical(_currentSession, session)) await invalidateSession(session.token);
      throw const LoginException('Phiên đăng nhập đã thay đổi hoặc hết hạn. Vui lòng đăng nhập lại.', code: 'session_expired');
    }
    try {
      final response = await _client.patch(Uri.parse('$_baseUrl/google/profile'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${session.token}'},
        body: jsonEncode({'name': name.trim(), 'phone': phone.trim(),
          if (password != null) 'password': password})).timeout(const Duration(seconds: 25));
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await invalidateSession(session.token, message: result['message'] as String?);
        }
        throw LoginException(result['message'] as String? ?? 'Không thể hoàn tất hồ sơ.',
          code: result['code'] as String? ?? 'profile_error');
      }
      if (!identical(_currentSession, session)) {
        throw const LoginException('Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.', code: 'session_expired');
      }
      final data = Map<String, dynamic>.from(result['data'] as Map);
      data['linkedExistingAccount'] = session.linkedExistingAccount;
      return await acceptSession(data, isActive: () => identical(_currentSession, session));
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể kết nối dịch vụ hồ sơ. Vui lòng thử lại.', code: 'connection_error');
    }
  }

  Future<CustomerProfile> fetchProfile(LoginResult session) => _requestProfile(session);

  Future<CustomerProfile> updateProfile(LoginResult session, {required String name, required String phone}) =>
    _requestProfile(session, fields: {'name': name.trim(), 'phone': phone.trim()});

  Future<CustomerProfile> _requestProfile(LoginResult session, {Map<String, String>? fields}) async {
    bool active() => !_disposed && _currentSession?.token == session.token &&
      session.expiresAt.isAfter(DateTime.now());
    if (!active()) throw const LoginException('Vui lòng đăng nhập lại để xem hồ sơ.', code: 'session_expired');
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final headers = {'Authorization': 'Bearer ${session.token}', 'Content-Type': 'application/json'};
      final response = await (fields == null ? _client.get(uri, headers: headers)
        : _client.patch(uri, headers: headers, body: jsonEncode(fields))).timeout(const Duration(seconds: 25));
      if (!active()) throw const LoginException('Phiên đăng nhập đã thay đổi hoặc hết hạn.', code: 'session_expired');
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode == 401 || response.statusCode == 403) {
        await invalidateSession(session.token, message: result['message'] as String?);
        throw LoginException(result['message'] as String? ?? 'Vui lòng đăng nhập lại.', code: 'session_expired');
      }
      if (response.statusCode != 200 || result['success'] != true) {
        throw LoginException(result['message'] as String? ?? 'Không thể tải hồ sơ.', code: 'profile_error');
      }
      final profile = CustomerProfile.fromJson(Map<String, dynamic>.from(result['data'] as Map));
      if (profile.id != session.customer.id) throw const FormatException('Profile identity mismatch');
      if (fields != null) {
        final current = _currentSession!;
        final customer = current.customer;
        _currentSession = LoginResult(token: current.token, expiresAt: current.expiresAt,
          linkedExistingAccount: current.linkedExistingAccount,
          customer: LoginCustomer(id: customer.id, name: profile.name, email: profile.email,
            phone: profile.phone, role: profile.role, hasPassword: customer.hasPassword,
            sessionProvider: customer.sessionProvider,
            profileCompleted: profile.name.trim().isNotEmpty && profile.phone.trim().isNotEmpty));
        _events.add(_currentSession);
      }
      return profile;
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể tải thông tin cá nhân. Vui lòng thử lại.', code: 'profile_connection_error');
    }
  }

  Future<void> logout({Future<void> Function()? clearProviderSession}) async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/logout'),
        headers: {'Authorization': 'Bearer ${session.token}'})
        .timeout(const Duration(seconds: 25));
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true || result['data']?['signedOut'] != true) {
        throw LoginException(result['message'] as String? ?? 'Chưa thu hồi được phiên trên máy chủ. Vui lòng thử lại.',
          code: result['code'] as String? ?? 'logout_error');
      }
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể xác nhận thu hồi phiên với máy chủ. Vui lòng thử đăng xuất lại.',
        code: 'logout_connection_error');
    }
    // An older request must not clear a more recent login.
    if (_currentSession != null && _currentSession!.token != session.token) return;
    final cleanupErrors = <String>[];
    try { await clearProviderSession?.call(); }
    catch (error) {
      cleanupErrors.add(error is LoginException ? error.message : 'Chưa xóa được phiên Google local.');
    }
    try {
      await invalidateSession(session.token, message: 'Đã đăng xuất.');
    } on LoginException catch (error) {
      cleanupErrors.add(error.message);
    }
    if (cleanupErrors.isNotEmpty) {
      throw LoginException('Phiên trên máy chủ đã được thu hồi. ${cleanupErrors.join(' ')}', code: 'logout_cleanup_error');
    }
  }

  void dispose() { _disposed = true; if (_ownsClient) _client.close(); }
}
