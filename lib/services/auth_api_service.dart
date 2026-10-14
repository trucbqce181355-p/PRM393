import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendAuthException extends StateError {
  BackendAuthException(this.status, super.message, {this.code});
  final int status;
  final String? code;
}

class AuthApiService {
  static http.Client client = http.Client();
  static Future<void> Function(String token, BackendAuthException error)?
  onSessionRejected;
  static String get baseUrl {
    const configured = String.fromEnvironment('AUTH_API_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && Platform.isAndroid
        ? 'http://10.0.2.2:5001/api/auth'
        : 'http://127.0.0.1:5001/api/auth';
  }

  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 25)),
      ).timeout(const Duration(seconds: 25));
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] != true) {
        throw BackendAuthException(
          response.statusCode,
          result['message'] as String? ??
              'Không thể xác thực hoặc lưu dữ liệu.',
          code: result['code'] as String?,
        );
      }
      return Map<String, dynamic>.from(result['data'] as Map);
    } on BackendAuthException catch (error) {
      if (token != null &&
          RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token) &&
          (error.status == 401 ||
              (error.status == 403 &&
                  (path == '/session' || path == '/profile')))) {
        await onSessionRejected?.call(token, error);
      }
      rethrow;
    } on TimeoutException {
      throw BackendAuthException(
        503,
        'Máy chủ xác thực không phản hồi. Vui lòng thử lại.',
      );
    } on SocketException {
      throw BackendAuthException(503, 'Không kết nối được máy chủ xác thực.');
    } on http.ClientException {
      throw BackendAuthException(503, 'Không kết nối được máy chủ xác thực.');
    } on FormatException {
      throw BackendAuthException(503, 'Máy chủ trả về dữ liệu không hợp lệ.');
    }
  }
}
