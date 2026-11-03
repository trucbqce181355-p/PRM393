import 'package:flutter/material.dart';

import 'flow_09_shipper_delivery.dart';
import 'mongodb_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MongoDBService.connect();
  } catch (error) {
    debugPrint('MongoDB is unavailable at startup: $error');
  }
  runApp(const ShipperDeliveryApp());
}

class ShipperDeliveryApp extends StatelessWidget {
  const ShipperDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow 9 · Giao hàng Shipper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ShipperOrdersScreen(),
    );
  }
}
