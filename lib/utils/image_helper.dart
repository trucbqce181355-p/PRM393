import 'dart:io';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    final trimmed = imageUrl.trim();

    if (trimmed.isEmpty) {
      content = errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha: 0.15),
            child: const Center(
              child: Icon(Icons.image, color: Colors.grey),
            ),
          );
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.withValues(alpha: 0.1),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
        },
      );
    } else {
      final file = File(trimmed);
      content = Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              );
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
