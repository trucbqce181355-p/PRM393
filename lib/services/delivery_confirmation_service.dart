import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../order_service.dart';

class DeliveryConfirmationService {
  const DeliveryConfirmationService._();

  static Future<bool> confirmDelivered({
    required String orderId,
    required XFile photo,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = photo.name.contains('.')
        ? photo.name.split('.').last
        : 'jpg';
    final savedPhoto = await File(photo.path).copy(
      '${directory.path}${Platform.pathSeparator}'
      'delivery-checkin-$orderId-${DateTime.now().millisecondsSinceEpoch}.$extension',
    );

    return OrderService.updateOrder(orderId, {
      'status': 'Đã hoàn thành',
      'deliveryPhotoPath': savedPhoto.path,
      'deliveredAt': DateTime.now().toIso8601String(),
    });
  }
}
