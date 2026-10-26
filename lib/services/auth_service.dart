import '../models/customer.dart';
import '../repositories/auth_repository.dart';
import 'auth_api_service.dart';

class OtpResult {
  const OtpResult({required this.isValid, required this.message});
  final bool isValid;
  final String message;
}

/// Registration orchestration. OTP and credentials are verified by the backend.
class AuthService {
  static String? _pendingEmail;
  static String? _challengeId;
  static String? _registrationToken;
  static int otpResendSeconds = 60;
  static bool get isLoggedIn => AuthRepository.sessionCustomer != null;
  static String? get pendingEmail => _pendingEmail;
  static String? get userName => AuthRepository.userName;
  static Customer? get currentUser => AuthRepository.sessionCustomer;
  static String? get userEmail => currentUser?.email;
  static bool get isAdmin => currentUser?.role == 'admin';
  static Future<String> login(String email, String password) =>
      AuthRepository.signInWithEmailPassword(email: email, password: password);
  static Future<void> logout() => AuthRepository.signOut();
  static DateTime? otpCreatedAt;
  static int otpDurationSeconds = 300;
  static String _otpPurpose = 'registration';
  static Future<bool> changeAdminPassword(
    String oldPassword,
    String newPassword,
  ) => AuthRepository.changeAdminPassword(oldPassword, newPassword);

  static Future<void> sendOtp(
    String targetEmail, {
    String purpose = 'registration',
  }) async {
    final email = targetEmail.trim().toLowerCase();
    final data = await AuthApiService.request(
      'POST',
      '/otp/request',
      body: {'email': email, 'purpose': purpose},
    );
    _pendingEmail = email;
    _challengeId = data['challengeId'] as String;
    _registrationToken = null;
    otpResendSeconds = data['resendAfter'] as int;
    otpCreatedAt = DateTime.now();
    otpDurationSeconds = data['expiresIn'] as int;
    _otpPurpose = purpose;
  }

  static Future<String> loginWithEmail(String email) async {
    try {
      await sendOtp(email, purpose: 'password_reset');
      return '';
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Không thể gửi OTP. Vui lòng thử lại.';
    }
  }

  static Future<String> resendOTP() async {
    if (_pendingEmail == null) return 'Vui lòng nhập email trước.';
    return loginWithEmail(_pendingEmail!);
  }

  static Future<OtpResult> verifyOTP(String otp) async {
    try {
      await verifyOtp(otp);
      return const OtpResult(isValid: true, message: 'Xác minh thành công.');
    } on StateError catch (error) {
      return OtpResult(isValid: false, message: error.message);
    } catch (_) {
      return const OtpResult(
        isValid: false,
        message: 'Không thể xác minh OTP.',
      );
    }
  }

  static Future<void> completePasswordReset(
    String email,
    String password,
  ) async {
    if (_otpPurpose != 'password_reset' ||
        _registrationToken == null ||
        email.trim().toLowerCase() != _pendingEmail) {
      throw StateError('Vui lòng xác minh OTP đặt lại mật khẩu trước.');
    }
    final validation = validatePassword(password);
    if (!validation.isValid) throw StateError(validation.firstErrorMessage!);
    await AuthApiService.request(
      'POST',
      '/password/reset',
      body: {'registrationToken': _registrationToken, 'password': password},
    );
    _registrationToken = null;
    _challengeId = null;
    _pendingEmail = null;
    otpCreatedAt = null;
  }

  static Future<bool> verifyOtp(String otp) async {
    if (_challengeId == null) throw StateError('Vui lòng gửi OTP trước.');
    final data = await AuthApiService.request(
      'POST',
      '/otp/verify',
      body: {'challengeId': _challengeId, 'otp': otp.trim()},
    );
    _registrationToken = data['registrationToken'] as String;
    _pendingEmail = data['email'] as String;
    return true;
  }

  static PasswordValidation validatePassword(String password) =>
      PasswordValidation.validate(password);

  static Future<Customer> completeRegistration({
    required String name,
    required String phone,
    required String password,
  }) async {
    if (_registrationToken == null || _otpPurpose != 'registration') {
      throw StateError('Vui lòng xác minh OTP trước khi đăng ký.');
    }
    final validation = validatePassword(password);
    if (!validation.isValid) {
      throw StateError(
        validation.firstErrorMessage ?? 'Mật khẩu không hợp lệ.',
      );
    }
    final data = await AuthApiService.request(
      'POST',
      '/register',
      body: {
        'registrationToken': _registrationToken,
        'name': name,
        'phone': phone,
        'password': password,
      },
    );
    final customer = await AuthRepository.acceptSession(data);
    _pendingEmail = null;
    _challengeId = null;
    _registrationToken = null;
    return customer;
  }

  static Future<void> completeAuthenticatedProfile({
    required String name,
    required String phone,
    String? password,
  }) async {
    final saved = await AuthRepository.saveCustomerProfile(
      name: name,
      phone: phone,
      password: password,
    );
    if (!saved) {
      throw StateError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
  }

  static Future<void> saveProfile(String name, {String? phone}) async {
    final saved = await AuthRepository.saveCustomerProfile(
      name: name,
      phone: phone ?? currentUser?.phone ?? '',
    );
    if (!saved) throw StateError('Không tìm thấy phiên đăng nhập.');
  }
}

/// Kết quả kiểm tra mật khẩu mạnh theo 3 tiêu chí bắt buộc
class PasswordValidation {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecial;
  final bool hasNoAccents;
  final bool hasNoEdgeSpaces;

  const PasswordValidation({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecial,
    required this.hasNoAccents,
    required this.hasNoEdgeSpaces,
  });

  /// Kiểm tra xem mật khẩu có thỏa mãn tất cả tiêu chí bắt buộc hay không
  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasNumber &&
      hasSpecial &&
      hasNoAccents &&
      hasNoEdgeSpaces;

  /// Điểm đánh giá độ mạnh (0 - 4)
  int get strengthScore {
    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase && hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecial) score++;
    return score;
  }

  /// Thông báo lỗi cụ thể cho tiêu chí đầu tiên chưa đạt
  String? get firstErrorMessage {
    if (!hasNoEdgeSpaces) {
      return 'Mật khẩu không được chứa khoảng trắng ở đầu hoặc cuối.';
    }
    if (!hasNoAccents) {
      return 'Mật khẩu không được chứa tiếng Việt có dấu (như đ, â, ớ...) hoặc ký tự không hợp lệ.';
    }
    if (!hasMinLength) {
      return 'Mật khẩu phải có độ dài tối thiểu từ 12 ký tự.';
    }
    if (!hasUppercase) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết hoa (A-Z).';
    }
    if (!hasLowercase) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết thường (a-z).';
    }
    if (!hasNumber) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số (0-9).';
    }
    if (!hasSpecial) {
      return 'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (!, @, #, \$, %, ^, *...).';
    }
    return null;
  }

  /// Phân tích và kiểm tra mật khẩu theo 3 quy tắc của hệ thống:
  /// 1. Tối thiểu 12 ký tự
  /// 2. Kết hợp 4 nhóm: chữ hoa (A-Z), chữ thường (a-z), chữ số (0-9), ký tự đặc biệt (!@#$%^&*...)
  /// 3. Không chứa tiếng Việt có dấu (đ, â, ớ...) và không chứa khoảng trắng ở đầu/cuối
  static PasswordValidation validate(String password) {
    final hasMinLength = password.length >= 12;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    // Ký tự đặc biệt trong bảng mã ASCII
    final hasSpecial = RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?`~]''')
        .hasMatch(password);

    // Kiểm tra ký tự tiếng Việt có dấu và ký tự non-ASCII
    final hasVietnameseAccents = RegExp(
      r'[àáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
      r'ÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ]',
    ).hasMatch(password);
    final hasNonAscii = RegExp(r'[^\x20-\x7E]').hasMatch(password);

    final hasEdgeSpaces = password.startsWith(' ') || password.endsWith(' ');

    return PasswordValidation(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecial: hasSpecial,
      hasNoAccents: !hasVietnameseAccents && !hasNonAscii,
      hasNoEdgeSpaces: !hasEdgeSpaces,
    );
  }
}
