import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Keys cho Flow Xác thực (Dev 2)
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserSession = 'user_session';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==========================================
  // --- AUTH & SESSION (Dev 2: Flow Xác thực) ---
  // ==========================================

  /// Xóa token và phiên làm việc khi đăng xuất (Logout)
  static Future<void> clearAuthSession() async {
    if (_prefs == null) await init();
    await _prefs?.remove(_keyAuthToken);
    await _prefs?.remove(_keyUserSession);
    await _prefs?.remove('saved_session_user_id');
  }

  // ==========================================
  // --- ORDERS ---
  // ==========================================
  static List<Map<String, dynamic>> getOrders({String? userEmail}) {
    final String? data = _prefs?.getString('orders');
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    var list = decoded.map((e) => e as Map<String, dynamic>).where((o) => o['id'] != '109283' && o['id'] != '109280').toList();
    if (userEmail != null && userEmail.isNotEmpty) {
      list = list.where((o) => (o['customerEmail'] ?? o['email'] ?? '').toString().toLowerCase() == userEmail.toLowerCase()).toList();
    }
    return list;
  }

  static Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    if (_prefs == null) await init();
    await _prefs?.setString('orders', jsonEncode(orders));
  }
  
  static Future<void> addOrder(Map<String, dynamic> order) async {
    final orders = getOrders();
    orders.insert(0, order);
    await saveOrders(orders);
  }

  // ==========================================
  // --- ADDRESSES ---
  // ==========================================
  static List<Map<String, dynamic>> getAddresses() {
    final String? data = _prefs?.getString('addresses');
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => e as Map<String, dynamic>).where((a) => (a['address'] ?? '') != 'Số 1, Đại Cồ Việt, Hà Nội').toList();
  }

  static Future<void> setDefaultAddress(int index) async {
    final addresses = getAddresses();
    if (index >= 0 && index < addresses.length) {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i]['isDefault'] = (i == index);
      }
      await saveAddresses(addresses);
    }
  }

  static Future<void> saveAddresses(List<Map<String, dynamic>> addresses) async {
    if (_prefs == null) await init();
    await _prefs?.setString('addresses', jsonEncode(addresses));
  }

  static Future<void> addAddress(Map<String, dynamic> address) async {
    final addresses = getAddresses();
    if (address['isDefault'] == true) {
      for (var a in addresses) {
        a['isDefault'] = false;
      }
    }
    addresses.add(address);
    await saveAddresses(addresses);
  }

  static Future<void> updateAddress(int index, Map<String, dynamic> updatedAddress) async {
    final addresses = getAddresses();
    if (index >= 0 && index < addresses.length) {
      if (updatedAddress['isDefault'] == true) {
        for (var a in addresses) {
          a['isDefault'] = false;
        }
      }
      addresses[index] = updatedAddress;
      await saveAddresses(addresses);
    }
  }

  static Future<void> deleteAddress(int index) async {
    final addresses = getAddresses();
    if (index >= 0 && index < addresses.length) {
      addresses.removeAt(index);
      await saveAddresses(addresses);
    }
  }

  // ==========================================
  // --- PAYMENT METHODS ---
  // ==========================================
  static List<Map<String, dynamic>> getPaymentMethods() {
    final String? data = _prefs?.getString('payments');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [
      {'title': 'Ví MoMo', 'subtitle': '0987***321', 'icon': 'wallet', 'isDefault': true},
      {'title': 'Thanh toán tiền mặt (COD)', 'subtitle': 'Thanh toán khi nhận hàng', 'icon': 'money', 'isDefault': false},
    ];
  }

  static Future<void> savePaymentMethods(List<Map<String, dynamic>> methods) async {
    if (_prefs == null) await init();
    await _prefs?.setString('payments', jsonEncode(methods));
  }

  static Future<void> addPaymentMethod(Map<String, dynamic> method) async {
    final methods = getPaymentMethods();
    if (method['isDefault'] == true) {
      for (var m in methods) {
        m['isDefault'] = false;
      }
    }
    methods.add(method);
    await savePaymentMethods(methods);
  }
}
