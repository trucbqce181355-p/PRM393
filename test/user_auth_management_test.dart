import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/models/customer.dart';
import 'package:traicay/services/auth_service.dart';
import 'package:traicay/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.init();
    DataService.customers.clear();
  });

  group('1. Yêu cầu và gửi lại OTP xác minh email', () {
    test('Gửi OTP qua email lưu trữ thông tin pendingEmail và tạo OTP 6 số', () async {
      final email = 'testuser@gmail.com';
      await AuthService.loginWithEmail(email);

      expect(AuthService.pendingEmail, equals(email));
      expect(AuthService.otpCreatedAt, isNotNull);
      expect(AuthService.remainingOtpAttempts, equals(5));
    });

    test('resendOTP gửi lại mã OTP mới và làm mới số lần thử', () async {
      final email = 'testuser2@gmail.com';
      await AuthService.loginWithEmail(email);

      // Thử sai 2 lần
      await AuthService.verifyOTP('000000');
      await AuthService.verifyOTP('111111');
      expect(AuthService.remainingOtpAttempts, equals(3));

      // Gửi lại OTP
      await AuthService.resendOTP();
      expect(AuthService.remainingOtpAttempts, equals(5));
      expect(AuthService.pendingEmail, equals(email));
    });
  });

  group('2. Xác minh OTP: Hết hạn (TTL) và Giới hạn số lần thử', () {
    test('Nhập sai quá 5 lần sẽ khóa OTP', () async {
      await AuthService.loginWithEmail('locktest@gmail.com');

      for (int i = 0; i < 4; i++) {
        final res = await AuthService.verifyOTP('99999$i');
        expect(res.isValid, isFalse);
        expect(res.isLocked, isFalse);
        expect(res.remainingAttempts, equals(4 - i));
      }

      // Lần thứ 5 sai -> Khóa
      final fifthRes = await AuthService.verifyOTP('999999');
      expect(fifthRes.isValid, isFalse);
      expect(fifthRes.isLocked, true);
      expect(fifthRes.remainingAttempts, equals(0));

      // Thử nhập lại dù đúng hay sai cũng bị từ chối do đã khóa
      final lockedRes = await AuthService.verifyOTP('123456');
      expect(lockedRes.isValid, isFalse);
      expect(lockedRes.isLocked, isTrue);
    });

    test('Xác minh thành công với mã đúng trước hạn', () async {
      await AuthService.loginWithEmail('successtest@gmail.com');
      final result = await AuthService.verifyOTP('123456');
      expect(result.isValid, isTrue);
      expect(result.isLocked, isFalse);
      expect(result.isExpired, isFalse);
    });
  });

  group('3. Quên mật khẩu bằng email, lấy lại mật khẩu và cập nhật CSDL', () {
    test('DataService.resetPasswordByEmail cập nhật mật khẩu mới thực tế', () async {
      final customer = Customer(
        id: 'c_test_pw',
        name: 'Trần Văn Hùng',
        email: 'hung@gmail.com',
        phone: '0987654321',
        password: 'old_password_123',
        totalSpent: 0.0,
        totalOrders: 0,
        isActive: true,
        memberTier: 'Đồng',
      );
      DataService.customers.add(customer);

      // Bước 1: Gửi OTP
      await AuthService.loginWithEmail(customer.email);

      // Bước 2: Xác thực OTP
      final otpResult = await AuthService.verifyOTP('123456');
      expect(otpResult.isValid, isTrue);

      // Bước 3: Đổi mật khẩu mới
      final resetSuccess = await DataService.resetPasswordByEmail(customer.email, 'new_password_999');
      expect(resetSuccess, isTrue);

      // Kiểm tra mật khẩu trong CSDL / danh sách DataService đã được cập nhật
      final updated = DataService.customers.firstWhere((c) => c.email == customer.email);
      expect(updated.password, equals('new_password_999'));

      // Đăng nhập bằng mật khẩu cũ phải thất bại
      expect(
        () async => await AuthService.login(customer.email, 'old_password_123'),
        throwsA(isA<Exception>()),
      );

      // Đăng nhập bằng mật khẩu mới phải thành công
      final loginResult = await AuthService.login(customer.email, 'new_password_999');
      expect(loginResult, equals('customer'));
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.userEmail, equals(customer.email));
    });
  });

  group('4. Lưu phiên, khôi phục phiên và thu hồi phiên local (Logout)', () {
    test('saveSession lưu vào SharedPreferences và AuthService.init khôi phục thành công', () async {
      await AuthService.saveSession(
        email: 'session@gmail.com',
        name: 'Session User',
        token: 'token_abc_123',
        expiryDays: 7,
      );

      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.userEmail, equals('session@gmail.com'));
      expect(AuthService.userName, equals('Session User'));

      // Mô phỏng ứng dụng khởi động lại
      await AuthService.init();
      expect(AuthService.isLoggedIn, isTrue);
      expect(AuthService.userEmail, equals('session@gmail.com'));
    });

    test('logout xóa sạch phiên trong RAM và SharedPreferences', () async {
      await AuthService.saveSession(
        email: 'logout_test@gmail.com',
        name: 'Logout User',
        token: 'token_xyz_789',
      );
      expect(AuthService.isLoggedIn, isTrue);

      // Thực hiện Logout
      await AuthService.logout();

      // Kiểm tra RAM
      expect(AuthService.isLoggedIn, isFalse);
      expect(AuthService.userEmail, isNull);
      expect(AuthService.userName, isNull);

      // Kiểm tra SharedPreferences đã bị xóa sạch
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_user_email'), isNull);
      expect(prefs.getString('auth_user_name'), isNull);
      expect(prefs.getInt('auth_session_expiry'), isNull);

      // Khởi động lại app sau khi logout không khôi phục phiên cũ
      await AuthService.init();
      expect(AuthService.isLoggedIn, isFalse);
    });
  });
}
