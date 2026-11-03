// Author: Chih An (GitHub: ChangChinAn)
// UC02: Gọi API xác minh OTP; server quyết định hạn dùng và số lần thử.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'otp_request_service.dart';

class OtpVerificationException implements Exception {
  const OtpVerificationException(
    this.message, {
    required this.code,
    this.remainingAttempts,
  });
  final String message;
  final String code;
  final int? remainingAttempts;
  bool get terminal => ['otp_expired', 'otp_locked', 'otp_used'].contains(code);
}

class OtpVerificationResult {
  const OtpVerificationResult({
    required this.email,
    required this.verificationToken,
    required this.expiresIn,
  });
  final String email;
  final String verificationToken;
  final int expiresIn;
}

class OtpVerificationService {
  OtpVerificationService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? OtpRequestService.defaultBaseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<OtpVerificationResult> verify(String challengeId, String otp) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/otp/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'challengeId': challengeId, 'otp': otp.trim()}),
          )
          .timeout(const Duration(seconds: 25));
      final result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true) {
        throw OtpVerificationException(
          result['message'] as String? ?? 'Không thể xác minh OTP.',
          code: result['code'] as String? ?? 'server_error',
          remainingAttempts: (result['remainingAttempts'] as num?)?.toInt(),
        );
      }
      final data = Map<String, dynamic>.from(result['data'] as Map);
      if (data['verified'] != true) {
        throw const FormatException('Missing verification');
      }
      return OtpVerificationResult(
        email: data['email'] as String,
        verificationToken: data['verificationToken'] as String,
        expiresIn: data['expiresIn'] as int,
      );
    } on OtpVerificationException {
      rethrow;
    } catch (_) {
      throw const OtpVerificationException(
        'Không thể kết nối dịch vụ xác minh. Vui lòng thử lại.',
        code: 'connection_error',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
