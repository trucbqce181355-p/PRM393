import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class OtpRequestException implements Exception {
  const OtpRequestException(this.message, {this.retryAfter = 0});
  final String message;
  final int retryAfter;
  @override
  String toString() => message;
}

class EmailOtpChallenge {
  const EmailOtpChallenge({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
    required this.resendAt,
  });
  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime resendAt;
  int resendSeconds(DateTime now) =>
      max(0, (resendAt.difference(now).inMilliseconds / 1000).ceil());
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'resendAt': resendAt.toIso8601String(),
  };
  factory EmailOtpChallenge.fromJson(Map<String, dynamic> json) =>
      EmailOtpChallenge(
        id: json['id'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        resendAt: DateTime.parse(json['resendAt'] as String),
      );
}

enum OtpCheckStatus { valid, invalid, expired, locked, used }

class OtpCheck {
  const OtpCheck(this.status, {this.remainingAttempts = 0});
  final OtpCheckStatus status;
  final int remainingAttempts;
}

abstract class RegistrationOtpStore {
  Future<bool> emailExists(String email);
  Future<void> reserve(String email, DateTime now);
  Future<void> create(EmailOtpChallenge challenge, String codeHash);
  Future<void> activate(EmailOtpChallenge challenge);
  Future<void> remove(String id);
  Future<EmailOtpChallenge?> active(String id, DateTime now);
  Future<OtpCheck> verify(String id, String codeHash, DateTime now);
}

abstract class OtpChallengeCache {
  Future<void> save(EmailOtpChallenge challenge);
  Future<EmailOtpChallenge?> read();
  Future<void> clear();
}

typedef OtpEmailSender = Future<void> Function(String email, String code);
String otpDigest(String value) => sha256.convert(utf8.encode(value)).toString();

/// UC01 adapted to main's direct MongoDB + Hive architecture.
class RegistrationOtpService {
  RegistrationOtpService({
    required this.store,
    required this.cache,
    required this.sendEmail,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RegistrationOtpStore store;
  final OtpChallengeCache cache;
  final OtpEmailSender sendEmail;
  final DateTime Function() now;
  bool _sending = false;
  static const lifetime = Duration(minutes: 5);
  static const resendDelay = Duration(seconds: 60);

  Future<EmailOtpChallenge> request(String value) async {
    final email = value.trim().toLowerCase();
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw const OtpRequestException('Vui lòng nhập địa chỉ email hợp lệ.');
    }
    if (_sending) {
      throw const OtpRequestException('Yêu cầu đang được gửi. Vui lòng chờ.');
    }
    _sending = true;
    try {
      if (await store.emailExists(email)) {
        throw const OtpRequestException('Email này đã được đăng ký.');
      }
      final createdAt = now();
      await store.reserve(email, createdAt);
      final random = Random.secure();
      final id = base64UrlEncode(List.generate(32, (_) => random.nextInt(256)))
          .replaceAll('=', '');
      final code = (100000 + random.nextInt(900000)).toString();
      final challenge = EmailOtpChallenge(
        id: id,
        email: email,
        createdAt: createdAt,
        expiresAt: createdAt.add(lifetime),
        resendAt: createdAt.add(resendDelay),
      );
      await store.create(challenge, otpDigest('$id:$code'));
      try {
        await sendEmail(email, code);
      } on OtpRequestException {
        await store.remove(id);
        rethrow;
      } catch (_) {
        await store.remove(id);
        throw const OtpRequestException(
          'Không thể gửi email xác minh. Vui lòng kiểm tra email và thử lại sau.',
          retryAfter: 60,
        );
      }
      await store.activate(challenge);
      // Hive holds metadata only; a cache error must not invalidate delivered mail.
      try {
        await cache.save(challenge);
      } catch (_) {}
      return challenge;
    } on OtpRequestException {
      rethrow;
    } catch (_) {
      throw const OtpRequestException(
        'Không kết nối được dịch vụ xác minh. Vui lòng thử lại.',
      );
    } finally {
      _sending = false;
    }
  }

  Future<EmailOtpChallenge?> restore() async {
    try {
      final cached = await cache.read();
      if (cached == null) return null;
      final challenge = await store.active(cached.id, now());
      if (challenge == null) await cache.clear();
      return challenge;
    } catch (_) {
      return null;
    }
  }

  Future<OtpCheck> verify(EmailOtpChallenge challenge, String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const OtpRequestException('Vui lòng nhập đúng 6 chữ số OTP.');
    }
    try {
      final result = await store.verify(
        challenge.id,
        otpDigest(challenge.id + ':' + code),
        now(),
      );
      if (result.status == OtpCheckStatus.valid) {
        try {
          await cache.clear();
        } catch (_) {}
      }
      return result;
    } catch (_) {
      throw const OtpRequestException(
        'Không kết nối được dịch vụ xác minh. Vui lòng thử lại.',
      );
    }
  }
}
