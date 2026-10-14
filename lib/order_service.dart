import 'package:mongo_dart/mongo_dart.dart' as mongo;

import 'mongodb_service.dart';

class OrderService {
  static const String collectionName = 'orders';

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final documents = await MongoDBService.getCollection(collectionName)
        .find(mongo.where.sortBy('createdAt', descending: true))
        .toList();

    return documents.map((document) {
      final order = Map<String, dynamic>.from(document);
      order.remove('_id');
      return order;
    }).toList();
  }

  static Future<void> addOrder(Map<String, dynamic> order) async {
    final document = Map<String, dynamic>.from(order)
      ..putIfAbsent('createdAt', DateTime.now);
    final result = await MongoDBService.getCollection(collectionName)
        .insertOne(document);

    if (!result.isSuccess) {
      throw StateError('MongoDB could not save order ${order['id']}.');
    }
  }

  static Future<bool> updateOrder(
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (updates.isEmpty) return false;

    final result = await MongoDBService.getCollection(collectionName)
        .updateOne(mongo.where.eq('id', id), {
          r'$set': {...updates, 'updatedAt': DateTime.now()},
        });

    return result.nMatched > 0;
  }

  static Map<String, dynamic> mergeUpdates(
    Map<String, dynamic> order,
    Map<String, dynamic> updates,
  ) {
    return {...order, ...updates};
  }
}
