import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MongoDBService {
  static Db? _db;

  // Tên database
  static const String _dbName = "traicay_db";

  static Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;

    try {
      String host = '127.0.0.1'; // Mặc định cho iOS, Windows, Web, Linux

      if (!kIsWeb && Platform.isAndroid) {
        // Android Emulator sử dụng 10.0.2.2 để trỏ tới localhost của máy tính
        host = '10.0.2.2';
      }

      String uri = "mongodb://$host:27017/$_dbName";
      print("Đang kết nối tới MongoDB: $uri");
      
      _db = await Db.create(uri);
      await _db!.open();
      print("Kết nối MongoDB thành công!");


    } catch (e) {
      print("Lỗi kết nối MongoDB: $e");
    }
  }


  static DbCollection getCollection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      throw Exception("MongoDB chưa được kết nối! Vui lòng gọi MongoDBService.connect() trước.");
    }
    return _db!.collection(collectionName);
  }

  // Đóng kết nối
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      print("Đã đóng kết nối MongoDB.");
    }
  }
}
