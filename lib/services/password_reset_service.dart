// Author: Chih An (GitHub: ChangChinAn)
// UC04: Gọi API đặt lại mật khẩu với proof OTP password_reset.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'otp_request_service.dart';

class PasswordResetException implements Exception {
  const PasswordResetException(this.message, {required this.code});
  final String message;
  final String code;
  bool get needsNewVerification => ['verification_expired', 'account_missing', 'account_locked'].contains(code);
}

class PasswordResetService {
  PasswordResetService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(), _ownsClient = client == null,
        _baseUrl = baseUrl ?? OtpRequestService.defaultBaseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<void> reset({required String verificationToken, required String password}) async {
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'verificationToken': verificationToken, 'password': password}))
        .timeout(const Duration(seconds: 25));
      final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true) {
        throw PasswordResetException(result['message'] as String? ?? 'Không thể đặt lại mật khẩu.',
          code: result['code'] as String? ?? 'server_error');
      }
      if (result['data']['reset'] != true) throw const FormatException('Missing reset confirmation');
    } on PasswordResetException {
      rethrow;
    } catch (_) {
      throw const PasswordResetException('Không thể kết nối dịch vụ đặt lại mật khẩu. Vui lòng thử lại.', code: 'connection_error');
    }
  }
  void dispose() { if (_ownsClient) _client.close(); }
}
