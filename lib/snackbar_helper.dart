import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.redAccent, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, Colors.blueAccent, Icons.info_outline);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
