// Author: Chih An (GitHub: ChangChinAn)
// UC05–UC06: Gọi đăng nhập email và nhận thông tin đăng nhập email/Google từ server.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'otp_request_service.dart';

class LoginException implements Exception {
  const LoginException(this.message, {required this.code});
  final String message;
  final String code;
}

class LoginCustomer {
  const LoginCustomer({required this.id, required this.name, required this.email, required this.role,
    this.profileCompleted = true, this.hasPassword = true, this.sessionProvider = 'password'});
  final String id;
  final String name;
  final String email;
  final String role;
  final bool profileCompleted;
  final bool hasPassword;
  final String sessionProvider;
}

class LoginResult {
  const LoginResult({required this.token, required this.expiresAt, required this.customer});
  final String token;
  final DateTime expiresAt;
  final LoginCustomer customer;
}

class LoginService {
  LoginService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(), _ownsClient = client == null,
        _baseUrl = baseUrl ?? OtpRequestService.defaultBaseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  static LoginResult? _currentSession;
  static LoginResult? get currentSession => _currentSession;

  LoginResult acceptSession(Map<String, dynamic> data) {
    final customer = Map<String, dynamic>.from(data['customer'] as Map);
    final token = data['token'] as String;
    final expiresAt = DateTime.parse(data['expiresAt'] as String);
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) throw const FormatException('Invalid login response');
    final session = LoginResult(token: token, expiresAt: expiresAt,
      customer: LoginCustomer(id: customer['id'] as String, name: customer['name'] as String,
        email: customer['email'] as String, role: customer['role'] as String,
        profileCompleted: customer['profileCompleted'] as bool? ?? true,
        hasPassword: customer['hasPassword'] as bool? ?? true,
        sessionProvider: customer['sessionProvider'] as String? ?? 'password'));
    _currentSession = session;
    return session;
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
      return acceptSession(data);
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException('Không thể kết nối dịch vụ đăng nhập. Vui lòng thử lại.', code: 'connection_error');
    }
  }
  void dispose() { if (_ownsClient) _client.close(); }
}
