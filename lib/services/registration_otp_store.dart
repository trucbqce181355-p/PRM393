import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

import 'mongodb_service.dart';
import 'registration_otp_service.dart';

class HiveOtpChallengeCache implements OtpChallengeCache {
  Future<Box<dynamic>> get _box => Hive.openBox<dynamic>('registration_otp');
  @override
  Future<void> save(EmailOtpChallenge challenge) async =>
      (await _box).put('active', challenge.toJson());
  @override
  Future<EmailOtpChallenge?> read() async {
    final value = (await _box).get('active');
    return value is Map
        ? EmailOtpChallenge.fromJson(Map<String, dynamic>.from(value))
        : null;
  }

  @override
  Future<void> clear() async => (await _box).delete('active');
}

class MongoRegistrationOtpStore implements RegistrationOtpStore {
  MongoRegistrationOtpStore({DbCollection Function(String)? collection})
    : _collection = collection ?? MongoDBService.getCollection;
  final DbCollection Function(String) _collection;
  // The legacy wrapper discards command errors; inspect modern results.
  Future<Map<String, dynamic>?> _modify(
    DbCollection collection, {
    required Map<String, dynamic> query,
    required Map<String, dynamic> update,
    bool upsert = false,
    bool returnNew = true,
  }) async {
    final result = await collection.modernFindAndModify(
      query: query,
      update: update,
      upsert: upsert,
      returnNew: returnNew,
    );
    if (!result.success) {
      throw MongoDartError(
        result.errmsg ?? 'MongoDB write failed',
        mongoCode: result.code,
      );
    }
    return result.value;
  }

  DbCollection get _challenges => _collection('registration_otp_challenges');
  @override
  Future<bool> emailExists(String email) async =>
      await _collection('users').findOne({
        r'$or': [
          {'emailNormalized': email},
          {
            'email': {
              r'$regex': '^' + RegExp.escape(email) + r'$',
              r'$options': 'i',
            },
          },
        ],
      }) !=
      null;

  @override
  Future<void> reserve(String email, DateTime now) async {
    final slots = _collection('registration_otp_slots');
    final key = otpDigest(email);
    // The unique _id prevents simultaneous requests claiming the same send slot.
    try {
      await _modify(
        slots,
        query: {
          '_id': key,
          'nextAllowedAt': {r'$lte': now},
        },
        update: {
          r'$set': {
            'nextAllowedAt': now.add(RegistrationOtpService.resendDelay),
          },
        },
        upsert: true,
        returnNew: true,
      );
    } on MongoDartError catch (error) {
      if (error.mongoCode != 11000 && !error.toString().contains('11000'))
        rethrow;
      final current = await slots.findOne({'_id': key});
      final next = current?['nextAllowedAt'] as DateTime?;
      final seconds = next == null
          ? 60
          : ((next.difference(now).inMilliseconds / 1000).ceil()).clamp(1, 60);
      throw OtpRequestException(
        'Vui lòng chờ $seconds giây trước khi gửi lại OTP.',
        retryAfter: seconds,
      );
    }
    final bucket =
        now.millisecondsSinceEpoch ~/ const Duration(hours: 1).inMilliseconds;
    final result = await _modify(
      _collection('registration_otp_limits'),
      query: {'_id': '$key:$bucket'},
      update: {
        r'$inc': {'count': 1},
        r'$setOnInsert': {'createdAt': now},
      },
      upsert: true,
      returnNew: true,
    );
    if ((result?['count'] as num? ?? 0) > 10) {
      final nextHour = DateTime.fromMillisecondsSinceEpoch(
        (bucket + 1) * const Duration(hours: 1).inMilliseconds,
      );
      final retry = (nextHour.difference(now).inMilliseconds / 1000).ceil();
      throw OtpRequestException(
        'Bạn đã yêu cầu quá nhiều mã. Vui lòng thử lại sau.',
        retryAfter: retry,
      );
    }
  }

  @override
  Future<void> create(EmailOtpChallenge challenge, String codeHash) async {
    await _challenges.insertOne({
      '_id': challenge.id,
      'email': challenge.email,
      'otpHash': codeHash,
      'createdAt': challenge.createdAt,
      'expiresAt': challenge.expiresAt,
      'resendAt': challenge.resendAt,
      'state': 'sending',
      'attempts': 0,
    });
  }

  @override
  Future<void> activate(EmailOtpChallenge challenge) async {
    await _challenges.updateMany(
      {
        'email': challenge.email,
        '_id': {r'$ne': challenge.id},
        'state': 'sent',
      },
      {
        r'$set': {'state': 'replaced'},
      },
    );
    await _challenges.updateOne(
      {'_id': challenge.id, 'state': 'sending'},
      {
        r'$set': {'state': 'sent'},
      },
    );
  }

  @override
  Future<void> remove(String id) async {
    await _challenges.deleteOne({'_id': id});
  }

  @override
  Future<EmailOtpChallenge?> active(String id, DateTime now) async {
    final value = await _challenges.findOne({
      '_id': id,
      'state': 'sent',
      'expiresAt': {r'$gt': now},
    });
    if (value == null) return null;
    return EmailOtpChallenge(
      id: id,
      email: value['email'] as String,
      createdAt: value['createdAt'] as DateTime,
      expiresAt: value['expiresAt'] as DateTime,
      resendAt: value['resendAt'] as DateTime,
    );
  }

  // Compatibility with main's existing next step; accepts only the delivered code.
  @override
  Future<OtpCheck> verify(String id, String codeHash, DateTime now) async {
    final result = await _modify(
      _challenges,
      query: {
        '_id': id,
        'state': 'sent',
        'expiresAt': {r'$gt': now},
        'attempts': {r'$lt': 5},
      },
      update: {
        r'$inc': {'attempts': 1},
      },
      returnNew: true,
    );
    if (result == null) {
      final existing = await _challenges.findOne({'_id': id});
      if (existing?['state'] == 'verified')
        return const OtpCheck(OtpCheckStatus.used);
      if (existing != null && (existing['attempts'] as num) >= 5) {
        return const OtpCheck(OtpCheckStatus.locked);
      }
      return const OtpCheck(OtpCheckStatus.expired);
    }
    final remaining = 5 - (result['attempts'] as num).toInt();
    if (result['otpHash'] != codeHash) {
      return OtpCheck(
        remaining == 0 ? OtpCheckStatus.locked : OtpCheckStatus.invalid,
        remainingAttempts: remaining,
      );
    }
    final consumed = await _challenges.updateOne(
      {
        '_id': id,
        'state': 'sent',
        'otpHash': codeHash,
        'expiresAt': {r'$gt': now},
      },
      {
        r'$set': {'state': 'verified'},
      },
    );
    return OtpCheck(
      consumed.nModified == 1 ? OtpCheckStatus.valid : OtpCheckStatus.used,
      remainingAttempts: remaining,
    );
  }
}
