import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traicay/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.logout();
  });

  group('Admin Auth & Password Tests', () {
    test('Default admin credentials login successfully', () async {
      await AuthService.init();
      expect(AuthService.isAdmin, false);

      final role = await AuthService.login('admin@gmail.com', '123456');
      expect(role, 'admin');
      expect(AuthService.isAdmin, true);
      expect(AuthService.userName, 'Admin');
      expect(AuthService.userEmail, 'admin@gmail.com');
    });

    test('Changing admin password succeeds and persists login', () async {
      await AuthService.init();
      final loginInitial = await AuthService.login('admin@gmail.com', '123456');
      expect(loginInitial, 'admin');

      // Change password with wrong old password
      final failChange = await AuthService.changeAdminPassword('wrongpass', '654321');
      expect(failChange, false);

      // Change password with correct old password
      final successChange = await AuthService.changeAdminPassword('123456', '654321');
      expect(successChange, true);

      // Logout and try logging in with old password (should fail)
      AuthService.logout();
      expect(AuthService.isAdmin, false);

      expect(
        () async => await AuthService.login('admin@gmail.com', '123456'),
        throwsException,
      );

      // Login with new password (should succeed)
      final loginNew = await AuthService.login('admin@gmail.com', '654321');
      expect(loginNew, 'admin');
      expect(AuthService.isAdmin, true);
    });
  });
}
