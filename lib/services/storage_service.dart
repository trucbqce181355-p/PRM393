import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- ORDERS ---
  static List<Map<String, dynamic>> getOrders() {
    final String? data = _prefs?.getString('orders');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [
      {
        'id': '109283',
        'status': 'Đang xử lý',
        'items': 'Táo Fuji hữu cơ (x2)',
        'date': 'Hôm nay, 10:30 AM',
        'total': '9.98',
      },
      {
        'id': '109280',
        'status': 'Đang giao',
        'items': 'Chuối cao cấp (x1) + Nho mẫu đơn (x1)',
        'date': 'Hôm qua, 14:20 PM',
        'total': '14.48',
      }
    ];
  }

  static Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    if (_prefs == null) await init();
    await _prefs?.setString('orders', jsonEncode(orders));
  }
  
  static Future<void> addOrder(Map<String, dynamic> order) async {
    final orders = getOrders();
    orders.insert(0, order); // Add to top
    await saveOrders(orders);
  }

  // --- ADDRESSES ---
  static List<Map<String, dynamic>> getAddresses() {
    final String? data = _prefs?.getString('addresses');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [
      {'title': 'Nhà riêng', 'address': 'Số 1, Đại Cồ Việt, Hà Nội', 'phone': '0987654321', 'isDefault': true},
      {'title': 'Công ty', 'address': 'Tòa nhà FPT, Cầu Giấy, Hà Nội', 'phone': '0912345678', 'isDefault': false},
    ];
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

  // --- PAYMENT METHODS ---
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
