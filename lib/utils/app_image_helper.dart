import 'dart:io';
import 'package:flutter/material.dart';

class AppImageHelper {
  /// Renders an Image widget that properly supports Network URLs, local File paths, and fallbacks.
  static Widget buildImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    final path = (imageUrl ?? '').trim();

    Widget placeholder() {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: (height != null && height < 60) ? 24 : 48,
                color: Colors.grey.shade400,
              ),
            ),
          );
    }

    if (path.isEmpty) {
      return placeholder();
    }

    Widget imageWidget;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      );
    } else {
      try {
        final file = File(path);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => placeholder(),
          );
        } else {
          imageWidget = placeholder();
        }
      } catch (_) {
        imageWidget = placeholder();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Returns ImageProvider for BoxDecoration (NetworkImage or FileImage)
  static ImageProvider? getImageProvider(String? imageUrl) {
    final path = (imageUrl ?? '').trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return null;
  }
}
