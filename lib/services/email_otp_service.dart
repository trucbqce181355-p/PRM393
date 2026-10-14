import 'auth_api_service.dart';

/// Retains the server challenge for the following OTP verification step.
class EmailOtpService {
  static Map<String, dynamic>? _challenge;
  static String? get challengeId => _challenge?['challengeId'] as String?;
  static int get resendAfter => _challenge?['resendAfter'] as int? ?? 60;

  static Future<void> sendOtp(String email) async {
    final challenge = await AuthApiService.request(
      'POST',
      '/otp/request',
      body: {'email': email.trim().toLowerCase()},
    );
    // A failed resend must not replace the last successfully issued challenge.
    _challenge = challenge;
  }
}
