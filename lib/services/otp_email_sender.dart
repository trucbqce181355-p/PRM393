import 'dart:convert';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'registration_otp_service.dart';

/// Desktop configuration is read at runtime; credentials are not build inputs.
Future<void> sendRegistrationOtpEmail(String email, String code) async {
  var username = Platform.environment['SMTP_USERNAME'] ?? '';
  var password = Platform.environment['SMTP_PASSWORD'] ?? '';
  if ((username.isEmpty || password.isEmpty) &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    final configured = Platform.environment['FRUITOPIA_SMTP_CONFIG'];
    final file = File(configured ?? 'smtp.local.json');
    if (await file.exists()) {
      final values = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      username = values['SMTP_USERNAME'] as String? ?? '';
      password = values['SMTP_PASSWORD'] as String? ?? '';
    }
  }
  if (username.isEmpty || password.isEmpty) {
    throw const OtpRequestException('Dịch vụ gửi email chưa được cấu hình.');
  }
  final message = Message()
    ..from = Address(username, 'Fruitopia')
    ..recipients.add(email)
    ..subject = 'Mã xác minh email Fruitopia'
    ..text = 'Mã xác minh của bạn: $code.\n'
        'Mã có hiệu lực 5 phút. Không chia sẻ mã này với bất kỳ ai.';
  await send(message, gmail(username, password),
    timeout: const Duration(seconds: 20));
}
