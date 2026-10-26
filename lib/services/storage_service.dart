import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Xóa triệt để các dữ liệu mẫu cũ đã lưu trong SharedPreferences
    final String? ordersData = _prefs?.getString('orders');
    if (ordersData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(ordersData);
        final cleaned = decoded.where((e) {
          final id = e['id']?.toString() ?? '';
          return id != '109283' && id != '109280';
        }).toList();
        await _prefs?.setString('orders', jsonEncode(cleaned));
      } catch (_) {}
    }

    final String? addrData = _prefs?.getString('addresses');
    if (addrData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(addrData);
        final cleaned = decoded.where((e) {
          final addr = e['address']?.toString() ?? '';
          return !addr.contains('Đại Cồ Việt') && !addr.contains('FPT');
        }).toList();
        await _prefs?.setString('addresses', jsonEncode(cleaned));
      } catch (_) {}
    }
  }

  // --- ORDERS ---
  static List<Map<String, dynamic>> getOrders({String? userEmail}) {
    final key = (userEmail != null && userEmail.isNotEmpty) ? 'orders_$userEmail' : 'orders';
    final String? data = _prefs?.getString(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => e as Map<String, dynamic>)
          .where((o) => o['id'] != '109283' && o['id'] != '109280')
          .toList();
    }
    // Khách mới chưa có đơn hàng: trả về danh sách RỖNG, không có dữ liệu mẫu
    return [];
  }

  static Future<void> saveOrders(List<Map<String, dynamic>> orders, {String? userEmail}) async {
    if (_prefs == null) await init();
    final key = (userEmail != null && userEmail.isNotEmpty) ? 'orders_$userEmail' : 'orders';
    await _prefs?.setString(key, jsonEncode(orders));
    if (key != 'orders') {
      await _prefs?.setString('orders', jsonEncode(orders));
    }
  }
  
  static Future<void> addOrder(Map<String, dynamic> order, {String? userEmail}) async {
    final orders = getOrders(userEmail: userEmail);
    orders.insert(0, order); // Add to top
    await saveOrders(orders, userEmail: userEmail);
  }

  // --- ADDRESSES ---
  static List<Map<String, dynamic>> getAddresses() {
    final String? data = _prefs?.getString('addresses');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => e as Map<String, dynamic>)
          .where((a) => !a['address'].toString().contains('Đại Cồ Việt') && !a['address'].toString().contains('FPT'))
          .toList();
    }
    // Khách mới chưa có địa chỉ: trả về danh sách RỖNG, không có dữ liệu mẫu
    return [];
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

  static Future<void> setDefaultAddress(int index) async {
    final addresses = getAddresses();
    if (index >= 0 && index < addresses.length) {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i]['isDefault'] = (i == index);
      }
      await saveAddresses(addresses);
    }
  }

  // --- PAYMENT METHODS ---
  static List<Map<String, dynamic>> getPaymentMethods() {
    final String? data = _prefs?.getString('payments');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [
      {'title': 'Thanh toán tiền mặt (COD)', 'subtitle': 'Thanh toán khi nhận hàng', 'icon': 'money', 'isDefault': true},
      {'title': 'Ví MoMo', 'subtitle': 'Thanh toán qua ví điện tử MoMo', 'icon': 'wallet', 'isDefault': false},
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

  static Future<void> updatePaymentMethod(int index, Map<String, dynamic> updatedMethod) async {
    final methods = getPaymentMethods();
    if (index >= 0 && index < methods.length) {
      if (updatedMethod['isDefault'] == true) {
        for (var m in methods) {
          m['isDefault'] = false;
        }
      }
      methods[index] = updatedMethod;
      await savePaymentMethods(methods);
    }
  }

  static Future<void> deletePaymentMethod(int index) async {
    final methods = getPaymentMethods();
    if (index >= 0 && index < methods.length) {
      final wasDefault = methods[index]['isDefault'] == true;
      methods.removeAt(index);
      if (wasDefault && methods.isNotEmpty) {
        methods[0]['isDefault'] = true;
      }
      await savePaymentMethods(methods);
    }
  }

  static Future<void> setDefaultPaymentMethod(int index) async {
    final methods = getPaymentMethods();
    if (index >= 0 && index < methods.length) {
      for (int i = 0; i < methods.length; i++) {
        methods[i]['isDefault'] = (i == index);
      }
      await savePaymentMethods(methods);
    }
  }
}
