import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api'; // Trỏ về máy host khi chạy Android Emulator
    }
    return 'http://127.0.0.1:5000/api'; // Windows, iOS, Web
  }

  // --- HỒ SƠ NGƯỜI DÙNG ---
  // --- ĐƠN HÀNG ---
  static Future<Map<String, dynamic>?> createOrder({
    required String customerId,
    required String customerName,
    required String address,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
    String? idToken,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (idToken != null) headers['Authorization'] = 'Bearer $idToken';

      final res = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: jsonEncode({
          'customerId': customerId,
          'customerName': customerName,
          'address': address,
          'phone': phone,
          'items': items,
          'total': total,
          'paymentMethod': paymentMethod,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['data'];
      }
    } catch (e) {
      print('[ApiService] createOrder error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getOrders([String? customerId]) async {
    try {
      final uri = customerId != null
          ? Uri.parse('$baseUrl/orders?customerId=$customerId')
          : Uri.parse('$baseUrl/orders');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body)['data'];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('[ApiService] getOrders error: $e');
    }
    return [];
  }

  static Future<bool> updateOrderStatus(String orderId, String status, [String? note]) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status, 'note': note}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] updateOrderStatus error: $e');
      return false;
    }
  }
}
