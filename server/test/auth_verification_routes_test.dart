import 'dart:convert';

import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/database.dart';
import 'package:linguaquest_server/src/email_sender.dart';
import 'package:linguaquest_server/src/routes.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

const _config = AppConfig(port: 0, databaseUrl: 'x', jwtSecret: 'test-secret');

Future<Response> _post(Router router, String path, Map<String, dynamic> body) {
  return router(Request(
    'POST',
    Uri.parse('http://localhost$path'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  ));
}

void main() {
  test('register creates an unverified user and emails a code, no token', () async {
    final db = _AuthTestDatabase();
    final email = FakeEmailSender();
    final router = buildRouter(_config, db, emailSender: email);

    final res = await _post(router, '/auth/register',
        {'name': 'Ada', 'email': 'ada@lingua.quest', 'password': 'secret1'});
    final body = jsonDecode(await res.readAsString());

    expect(res.statusCode, 202);
    expect(body['status'], 'verification_required');
    expect(body.containsKey('token'), isFalse);
    expect(db.users.values.single['email_verified'], false);
    expect(email.lastTo, 'ada@lingua.quest');
    expect(email.lastCode, hasLength(6));
  });

  test('register rejects a garbled email', () async {
    final db = _AuthTestDatabase();
    final router = buildRouter(_config, db, emailSender: FakeEmailSender());
    final res = await _post(router, '/auth/register',
        {'name': 'Ada', 'email': 'ada@bad', 'password': 'secret1'});
    expect(res.statusCode, 400);
  });

  test('verify with the wrong code increments attempts and 400s', () async {
    final db = _AuthTestDatabase();
    final email = FakeEmailSender();
    final router = buildRouter(_config, db, emailSender: email);
    await _post(router, '/auth/register',
        {'name': 'Ada', 'email': 'ada@lingua.quest', 'password': 'secret1'});

    final res = await _post(router, '/auth/verify',
        {'email': 'ada@lingua.quest', 'code': '000000'});
    expect(res.statusCode, 400);
    expect(db.codes.values.single['attempts'], 1);
  });

  test('verify with the correct code verifies + returns a token', () async {
    final db = _AuthTestDatabase();
    final email = FakeEmailSender();
    final router = buildRouter(_config, db, emailSender: email);
    await _post(router, '/auth/register',
        {'name': 'Ada', 'email': 'ada@lingua.quest', 'password': 'secret1'});

    final res = await _post(router, '/auth/verify',
        {'email': 'ada@lingua.quest', 'code': email.lastCode});
    final body = jsonDecode(await res.readAsString());
    expect(res.statusCode, 200);
    expect((body['token'] as String).isNotEmpty, isTrue);
    expect(body['user']['emailVerified'], true);
    expect(db.users.values.single['email_verified'], true);
    expect(db.codes, isEmpty);
  });

  test('login is blocked until verified, then succeeds', () async {
    final db = _AuthTestDatabase();
    final email = FakeEmailSender();
    final router = buildRouter(_config, db, emailSender: email);
    await _post(router, '/auth/register',
        {'name': 'Ada', 'email': 'ada@lingua.quest', 'password': 'secret1'});

    final blocked = await _post(router, '/auth/login',
        {'email': 'ada@lingua.quest', 'password': 'secret1'});
    expect(blocked.statusCode, 403);
    expect(jsonDecode(await blocked.readAsString())['error'],
        'email_not_verified');

    await _post(router, '/auth/verify',
        {'email': 'ada@lingua.quest', 'code': email.lastCode});
    final ok = await _post(router, '/auth/login',
        {'email': 'ada@lingua.quest', 'password': 'secret1'});
    expect(ok.statusCode, 200);
    expect((jsonDecode(await ok.readAsString())['token'] as String).isNotEmpty,
        isTrue);
  });

  test('resend within cooldown returns 429', () async {
    final db = _AuthTestDatabase();
    final email = FakeEmailSender();
    final router = buildRouter(_config, db, emailSender: email);
    await _post(router, '/auth/register',
        {'name': 'Ada', 'email': 'ada@lingua.quest', 'password': 'secret1'});

    final res = await _post(router, '/auth/resend', {'email': 'ada@lingua.quest'});
    expect(res.statusCode, 429);
  });
}

class _AuthTestDatabase extends AppDatabase {
  _AuthTestDatabase() : super(_UnusedConnection());

  final Map<String, Map<String, dynamic>> users = {};
  final Map<String, Map<String, dynamic>> codes = {};

  @override
  Future<Map<String, dynamic>?> userByEmail(String email) async {
    for (final u in users.values) {
      if (u['email'] == email) return u;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> userById(String uid) async => users[uid];

  @override
  Future<void> insertUser({
    required String id,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    required String name,
  }) async {
    final now = DateTime.now().toUtc();
    users[id] = {
      'id': id, 'email': email, 'password_hash': passwordHash,
      'password_salt': passwordSalt, 'name': name,
      'target_exam': 'HSK 1', 'level': 'Beginner', 'daily_goal': 10,
      'xp': 0, 'streak': 0, 'email_verified': false,
      'last_study_date': null, 'created_at': now, 'updated_at': now,
    };
  }

  @override
  Future<void> setEmailVerified(String uid) async {
    users[uid]!['email_verified'] = true;
  }

  @override
  Future<void> upsertVerificationCode(String uid,
      {required String codeHash,
      required String codeSalt,
      required DateTime expiresAt,
      required DateTime sentAt}) async {
    codes[uid] = {
      'uid': uid, 'code_hash': codeHash, 'code_salt': codeSalt,
      'expires_at': expiresAt, 'attempts': 0,
      'last_sent_at': sentAt, 'created_at': sentAt,
    };
  }

  @override
  Future<Map<String, dynamic>?> verificationCodeFor(String uid) async => codes[uid];

  @override
  Future<void> incrementVerificationAttempts(String uid) async {
    codes[uid]!['attempts'] = (codes[uid]!['attempts'] as int) + 1;
  }

  @override
  Future<void> deleteVerificationCode(String uid) async {
    codes.remove(uid);
  }
}

class _UnusedConnection implements Connection {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('connection should not be used in route tests');
}
