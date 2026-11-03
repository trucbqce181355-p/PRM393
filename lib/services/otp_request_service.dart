// Author: Chih An (GitHub: ChangChinAn)
// UC01: Gọi API yêu cầu và gửi lại OTP xác minh email.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OtpRequestException implements Exception {
  const OtpRequestException(this.message, {this.retryAfter = 0});
  final String message;
  final int retryAfter;
}

class OtpEmailChallenge {
  const OtpEmailChallenge({
    required this.id,
    required this.email,
    required this.expiresIn,
    required this.resendAfter,
  });
  final String id;
  final String email;
  final int expiresIn;
  final int resendAfter;
}

class OtpRequestService {
  OtpRequestService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? defaultBaseUrl,
      _ownsClient = client == null;
  final http.Client _client;
  final String _baseUrl;
  final bool _ownsClient;

  static String get defaultBaseUrl {
    const configured = String.fromEnvironment('AUTH_API_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && Platform.isAndroid
        ? 'http://10.0.2.2:5001/api/auth'
        : 'http://127.0.0.1:5001/api/auth';
  }

  Future<OtpEmailChallenge> request(String email) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/otp/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 25));
      final result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200 || result['success'] != true) {
        throw OtpRequestException(
          result['message'] as String? ?? 'Không thể gửi OTP.',
          retryAfter: (result['retryAfter'] as num?)?.toInt() ?? 0,
        );
      }
      final data = Map<String, dynamic>.from(result['data'] as Map);
      return OtpEmailChallenge(
        id: data['challengeId'] as String,
        email: data['email'] as String,
        expiresIn: data['expiresIn'] as int,
        resendAfter: data['resendAfter'] as int,
      );
    } on OtpRequestException {
      rethrow;
    } catch (_) {
      throw const OtpRequestException(
        'Không kết nối được dịch vụ gửi OTP. Vui lòng thử lại.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
