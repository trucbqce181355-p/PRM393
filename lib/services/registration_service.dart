// Author: Chih An (GitHub: ChangChinAn)
// UC03: Gọi API tạo tài khoản với bằng chứng email đã xác minh.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'otp_request_service.dart';

class RegistrationException implements Exception {
  const RegistrationException(this.message, {required this.code});
  final String message;
  final String code;
  bool get needsNewVerification => ['verification_expired', 'email_exists'].contains(code);
}

class RegisteredCustomer {
  const RegisteredCustomer({required this.id, required this.name,
    required this.email, required this.phone});
  final String id;
  final String name;
  final String email;
  final String phone;
}

class RegistrationValidation {
  static String? passwordError(String password) {
    if (password.length < 12 || password.length > 256 || password != password.trim() ||
        RegExp(r'[^\x20-\x7e]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password) || !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) || !RegExp(r'[^A-Za-z0-9 ]').hasMatch(password)) {
      return 'Mật khẩu từ 12 đến 256 ký tự không dấu, có chữ hoa, chữ thường, số và ký tự đặc biệt; không có khoảng trắng đầu/cuối.';
    }
    return null;
  }
}

class RegistrationService {
  RegistrationService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(), _ownsClient = client == null,
        _baseUrl = baseUrl ?? OtpRequestService.defaultBaseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<RegisteredCustomer> register({required String verificationToken,
    required String name, required String phone, required String password}) async {
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'verificationToken': verificationToken,
          'name': name.trim(), 'phone': phone.trim(), 'password': password}))
        .timeout(const Duration(seconds: 25));
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 201 || result['success'] != true) {
        throw RegistrationException(result['message'] as String? ?? 'Không thể tạo tài khoản.',
          code: result['code'] as String? ?? 'server_error');
      }
      final data = Map<String, dynamic>.from(result['data']['customer'] as Map);
      return RegisteredCustomer(id: data['id'] as String, name: data['name'] as String,
        email: data['email'] as String, phone: data['phone'] as String);
    } on RegistrationException {
      rethrow;
    } catch (_) {
      throw const RegistrationException('Không thể kết nối dịch vụ đăng ký. Vui lòng thử lại.', code: 'connection_error');
    }
  }
  void dispose() { if (_ownsClient) _client.close(); }
}
