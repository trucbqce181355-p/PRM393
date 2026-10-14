import 'dart:developer' show log;

import 'package:mongo_dart/mongo_dart.dart';

import 'dart:io' show Platform;

class MongoDBService {
  static Db? _db;

  static const String _dbName = 'traicay_db';
  static const String _configuredUri = String.fromEnvironment('MONGODB_URI');
  static const String _configuredHost = String.fromEnvironment('MONGODB_HOST');

  static Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;

    final uri = _connectionUri;
    final database = await Db.create(uri);
    try {
      await database.open();
      _db = database;
      await getCollection('orders')
          .createIndex(keys: {'id': 1}, unique: true, name: 'unique_order_id');
      log('Connected to MongoDB database $_dbName.', name: 'MongoDBService');
    } catch (e) {
      if (database.isConnected) {
        await database.close();
      }
      _db = null;
      log('MongoDB connection failed: $e', name: 'MongoDBService', error: e);
      rethrow;
    }
  }

  static String get _connectionUri {
    if (_configuredUri.isNotEmpty) return _configuredUri;

    final host = _configuredHost.isNotEmpty
        ? _configuredHost
        : (!bool.fromEnvironment('dart.library.js_interop') &&
                  Platform.isAndroid
              ? '10.0.2.2'
              : '127.0.0.1');
    return 'mongodb://$host:27017/$_dbName';
  }

  static DbCollection getCollection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      throw StateError(
        'MongoDB is not connected. Start MongoDB and connect before using '
        'the $collectionName collection.',
      );
    }
    return _db!.collection(collectionName);
  }

  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
    }
  }
}
