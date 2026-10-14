import 'dart:io' show stderr, stdout;

import 'package:flow_09_shipper_delivery/mongodb_service.dart';
import 'package:flow_09_shipper_delivery/order_service.dart';

Future<void> main() async {
  try {
    await MongoDBService.connect();

    final existingOrders = await OrderService.getOrders();
    if (existingOrders.isEmpty) {
      for (final order in _sampleOrders) {
        await OrderService.addOrder(order);
      }
      stdout.writeln('Inserted ${_sampleOrders.length} sample orders.');
    } else {
      stdout.writeln(
        'Keeping existing orders; found ${existingOrders.length} document(s).',
      );
    }

    final savedOrders = await OrderService.getOrders();
    stdout.writeln('Database: traicay_db');
    stdout.writeln('Collection: orders');
    stdout.writeln('Order documents: ${savedOrders.length}');
  } catch (error) {
    stderr.writeln('Could not initialize MongoDB database: $error');
    rethrow;
  } finally {
    await MongoDBService.close();
  }
}

final List<Map<String, dynamic>> _sampleOrders = [
  {
    'id': '109283',
    'status': 'Đang xử lý',
    'items': 'Táo Fuji hữu cơ (x2)',
    'date': 'Hôm nay, 10:30',
    'total': '9.98',
    'customerName': 'Nguyễn Minh Anh',
    'phone': '0987654321',
    'address': 'Số 1, Đại Cồ Việt, Bách Khoa, Hà Nội',
    'paymentMethod': 'COD',
    'paymentStatus': 'Chưa thanh toán',
    'createdAt': DateTime.now(),
  },
  {
    'id': '109280',
    'status': 'Đang giao',
    'items': 'Chuối cao cấp (x1) + Nho mẫu đơn (x1)',
    'date': 'Hôm qua, 14:20',
    'total': '14.48',
    'customerName': 'Trần Thu Hà',
    'phone': '0912345678',
    'address': 'Tòa nhà FPT, Cầu Giấy, Hà Nội',
    'paymentMethod': 'MOMO',
    'paymentStatus': 'Đã thanh toán',
    'shipperName': 'Shipper Demo',
    'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
  },
];
