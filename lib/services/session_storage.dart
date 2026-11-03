// Author: Chih An (GitHub: ChangChinAn)
// UC09: Chỉ lưu token ứng dụng trong kho bảo mật hệ điều hành.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'fruitopia.app_session_token';
  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<void> delete() => _storage.delete(key: _key);
}
