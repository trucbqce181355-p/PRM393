import 'auth_api_service.dart';

/// Retains the server challenge for the following OTP verification step.
class EmailOtpService {
  static Map<String, dynamic>? _challenge;
  static Map<String, dynamic>? _verification;
  static String? get challengeId => _challenge?['challengeId'] as String?;
  static int get resendAfter => _challenge?['resendAfter'] as int? ?? 60;
  static String? get registrationToken =>
      _verification?['registrationToken'] as String?;
  static String? get verifiedEmail => _verification?['email'] as String?;

  static Future<void> sendOtp(String email) async {
    final challenge = await AuthApiService.request(
      'POST',
      '/otp/request',
      body: {'email': email.trim().toLowerCase()},
    );
    // A failed resend must not replace the last successfully issued challenge.
    _challenge = challenge;
    _verification = null;
  }

  static Future<bool> verifyOtp(String otp) async {
    final id = challengeId;
    if (id == null) throw StateError('Vui lòng gửi OTP trước.');
    final verification = await AuthApiService.request(
      'POST',
      '/otp/verify',
      body: {'challengeId': id, 'otp': otp.trim()},
    );
    _verification = verification;
    return registrationToken != null && verifiedEmail != null;
  }

  static Future<void> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final proof = registrationToken;
    if (proof == null) {
      throw StateError('Vui lòng xác minh OTP trước khi đăng ký.');
    }
    await AuthApiService.request(
      'POST',
      '/register',
      body: {
        'registrationToken': proof,
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password,
      },
    );
    _challenge = null;
    _verification = null;
  }
}
