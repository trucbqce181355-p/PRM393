import 'package:flutter/services.dart';

/// Windows Credential Manager / Android Keystore. No plaintext fallback.
class SessionStorage {
  static const channel = MethodChannel('fruitopia/secure_session');
  static Future<String?> read() => channel.invokeMethod<String>('read');
  static Future<void> write(String token) =>
      channel.invokeMethod<void>('write', {'token': token});
  static Future<void> delete() => channel.invokeMethod<void>('delete');
}
