# Email Verification (OTP) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Require new users to verify ownership of their email via a 6-digit code before the account can be used; block unverified logins.

**Architecture:** Backend (`server/`, Dart shelf) adds an `email_verified` flag + a hashed-OTP table, a pluggable `EmailSender` (SMTP with a dev-console fallback), and `register`/`verify`/`resend`/`login` endpoint changes. Client (`linguaquest/`, Flutter) tightens email-format validation, adds a `verify-email` OTP screen, and routes unverified register/login into it. Offline/mock mode keeps the strict format check but simulates instant verification.

**Tech Stack:** Dart shelf + postgres + `mailer` (backend); Flutter + Riverpod + dio (client). Spec: `docs/superpowers/specs/2026-06-19-email-verification-otp-design.md`.

**Run server commands from `server/`, app commands from `linguaquest/`.** Server tests use fake `Connection`/`AppDatabase` subclasses (no real Postgres).

---

## File map

**Backend (`server/`):**
- Create: `lib/src/email_sender.dart` — `EmailSender` interface + `ConsoleEmailSender` + `SmtpEmailSender` + `EmailSender.fromConfig`.
- Modify: `lib/src/config.dart` — SMTP env fields.
- Modify: `lib/src/database.dart` — migration (email_verified, email_verification_codes) + verification DB methods.
- Modify: `lib/src/routes.dart` — `buildRouter` gains `emailSender`; `isValidEmail`/OTP helpers; register/verify/resend/login; `userDto`.
- Modify: `pubspec.yaml` — add `mailer`.
- Tests: `test/email_sender_test.dart`, `test/email_verification_db_test.dart`, `test/auth_verification_routes_test.dart`.

**Client (`linguaquest/`):**
- Create: `lib/core/utils/email_validation.dart`, `lib/features/auth/verify_email_screen.dart`.
- Modify: `lib/data/repositories/auth_repository.dart` (result types + new methods), `api_repositories.dart`, `mock_repositories.dart`, `lib/data/models/user_profile.dart`, `lib/core/state/app_controller.dart`, `lib/features/auth/login_screen.dart`, `register_screen.dart`, `lib/core/routing/app_router.dart`.
- Tests: `test/email_validation_test.dart`, `test/user_profile_verified_test.dart`, `test/mock_auth_verification_test.dart`.

---

## Task S1: Backend `EmailSender` + config

**Files:**
- Modify: `server/pubspec.yaml`, `server/lib/src/config.dart`
- Create: `server/lib/src/email_sender.dart`
- Test: `server/test/email_sender_test.dart`

- [ ] **Step 1: Add the `mailer` dependency**

In `server/pubspec.yaml`, under `dependencies:` (after `http: ^1.2.0`):

```yaml
  http: ^1.2.0
  mailer: ^6.1.0
```

Run: `cd server && dart pub get`
Expected: resolves, downloads `mailer`.

- [ ] **Step 2: Add SMTP fields to `AppConfig`**

Replace `server/lib/src/config.dart` entirely:

```dart
import 'dart:io';

class AppConfig {
  const AppConfig({
    required this.port,
    required this.databaseUrl,
    required this.jwtSecret,
    this.smtpHost = '',
    this.smtpPort = 587,
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.smtpFrom = 'no-reply@linguaquest.app',
  });

  final int port;
  final String databaseUrl;
  final String jwtSecret;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String smtpFrom;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      port: int.tryParse(_env('PORT', '8080')) ?? 8080,
      databaseUrl: _env(
        'DATABASE_URL',
        'postgresql://linguaquest:linguaquest@localhost:5432/linguaquest?sslmode=disable',
      ),
      jwtSecret: _env('JWT_SECRET', 'dev-secret-change-me'),
      smtpHost: _env('SMTP_HOST', ''),
      smtpPort: int.tryParse(_env('SMTP_PORT', '587')) ?? 587,
      smtpUsername: _env('SMTP_USERNAME', ''),
      smtpPassword: _env('SMTP_PASSWORD', ''),
      smtpFrom: _env('SMTP_FROM', 'no-reply@linguaquest.app'),
    );
  }
}

String _env(String key, String fallback) {
  return Platform.environment[key] ?? fallback;
}
```

- [ ] **Step 3: Write the failing test**

Create `server/test/email_sender_test.dart`:

```dart
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/email_sender.dart';
import 'package:test/test.dart';

void main() {
  test('ConsoleEmailSender records the code it would send', () async {
    final sender = ConsoleEmailSender();
    await sender.sendVerificationCode(to: 'a@b.co', code: '123456');
    expect(sender.lastTo, 'a@b.co');
    expect(sender.lastCode, '123456');
  });

  test('fromConfig uses console when SMTP host is empty', () {
    const config = AppConfig(port: 0, databaseUrl: 'x', jwtSecret: 'y');
    expect(EmailSender.fromConfig(config), isA<ConsoleEmailSender>());
  });

  test('fromConfig uses SMTP when host is set', () {
    const config = AppConfig(
      port: 0,
      databaseUrl: 'x',
      jwtSecret: 'y',
      smtpHost: 'smtp.example.com',
    );
    expect(EmailSender.fromConfig(config), isA<SmtpEmailSender>());
  });
}
```

- [ ] **Step 4: Run it, confirm FAIL**

Run: `cd server && dart test test/email_sender_test.dart`
Expected: FAIL — `email_sender.dart` does not exist.

- [ ] **Step 5: Implement `email_sender.dart`**

Create `server/lib/src/email_sender.dart`:

```dart
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'config.dart';

/// Sends transactional emails. The rest of the app depends only on this
/// interface; the concrete sender is chosen by [EmailSender.fromConfig].
abstract class EmailSender {
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  });

  factory EmailSender.fromConfig(AppConfig config) {
    if (config.smtpHost.trim().isEmpty) return ConsoleEmailSender();
    return SmtpEmailSender(config);
  }
}

/// Dev/CI fallback: logs the code to stdout instead of sending an email.
/// Also records the last call so tests can assert on it.
class ConsoleEmailSender implements EmailSender {
  String? lastTo;
  String? lastCode;

  @override
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  }) async {
    lastTo = to;
    lastCode = code;
    stdout.writeln('[email] verification code for $to: $code');
  }
}

/// Real SMTP delivery, used when SMTP_HOST is configured.
class SmtpEmailSender implements EmailSender {
  SmtpEmailSender(this._config);

  final AppConfig _config;

  @override
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  }) async {
    final server = SmtpServer(
      _config.smtpHost,
      port: _config.smtpPort,
      username: _config.smtpUsername.isEmpty ? null : _config.smtpUsername,
      password: _config.smtpPassword.isEmpty ? null : _config.smtpPassword,
    );
    final message = Message()
      ..from = Address(_config.smtpFrom, 'LinguaQuest')
      ..recipients.add(to)
      ..subject = 'Your LinguaQuest verification code'
      ..text =
          'Your verification code is $code. It expires in 10 minutes.';
    await send(message, server);
  }
}
```

- [ ] **Step 6: Run it, confirm PASS**

Run: `cd server && dart test test/email_sender_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add server/pubspec.yaml server/pubspec.lock server/lib/src/config.dart server/lib/src/email_sender.dart server/test/email_sender_test.dart
git commit -m "feat(server): pluggable EmailSender (SMTP + console) and SMTP config"
```

---

## Task S2: Backend DB migration + verification methods

**Files:**
- Modify: `server/lib/src/database.dart`
- Test: `server/test/email_verification_db_test.dart`

- [ ] **Step 1: Add the migration statements**

In `server/lib/src/database.dart`, in `migrate()`, immediately AFTER the existing
`await connection.execute("ALTER TABLE users ALTER COLUMN level SET DEFAULT 'Intermediate'");`
block (around line 48-50), add:

```dart
    // Email verification: backfill EXISTING users to verified (ADD COLUMN with
    // DEFAULT TRUE sets existing rows TRUE), then flip the default so NEW
    // registrations are created unverified. Idempotent across restarts.
    await connection.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT TRUE',
    );
    await connection.execute(
      'ALTER TABLE users ALTER COLUMN email_verified SET DEFAULT FALSE',
    );
    await connection.execute('''
CREATE TABLE IF NOT EXISTS email_verification_codes (
  uid TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  code_salt TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_sent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);
''');
```

- [ ] **Step 2: Write the failing test (recording-connection style)**

Create `server/test/email_verification_db_test.dart`:

```dart
import 'package:linguaquest_server/src/database.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('setEmailVerified issues the expected UPDATE', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    await database.setEmailVerified('user-1');
    expect(connection.lastSql, contains('UPDATE users'));
    expect(connection.lastSql, contains('email_verified=TRUE'));
    expect(connection.lastSql, contains('WHERE id=@uid'));
    expect(connection.lastParameters, {'uid': 'user-1'});
  });

  test('upsertVerificationCode upserts hash/salt/expiry and resets attempts',
      () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    final expires = DateTime.utc(2026, 6, 19, 10);
    final sent = DateTime.utc(2026, 6, 19, 9, 50);
    await database.upsertVerificationCode(
      'user-1',
      codeHash: 'H',
      codeSalt: 'S',
      expiresAt: expires,
      sentAt: sent,
    );
    expect(connection.lastSql, contains('INSERT INTO email_verification_codes'));
    expect(connection.lastSql, contains('ON CONFLICT (uid) DO UPDATE'));
    expect(connection.lastSql, contains('attempts=0'));
    expect(connection.lastParameters, {
      'uid': 'user-1',
      'codeHash': 'H',
      'codeSalt': 'S',
      'expiresAt': expires,
      'sentAt': sent,
    });
  });

  test('incrementVerificationAttempts bumps the counter', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    await database.incrementVerificationAttempts('user-1');
    expect(connection.lastSql, contains('UPDATE email_verification_codes'));
    expect(connection.lastSql, contains('attempts=attempts+1'));
    expect(connection.lastParameters, {'uid': 'user-1'});
  });

  test('deleteVerificationCode deletes by uid', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    await database.deleteVerificationCode('user-1');
    expect(connection.lastSql, contains('DELETE FROM email_verification_codes'));
    expect(connection.lastParameters, {'uid': 'user-1'});
  });
}

class _RecordingConnection implements Connection {
  String? lastSql;
  Object? lastParameters;

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    lastSql = query is Sql ? _sqlText(query) : query.toString();
    lastParameters = parameters;
    return _EmptyResult();
  }

  String _sqlText(Sql sql) => sql.toString();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyResult implements Result {
  @override
  dynamic noSuchMethod(Invocation invocation) => <ResultRow>[];
}
```

NOTE: `Sql.toString()` may not expose the raw text. If the recording test cannot read the
SQL text from a `Sql` object, store the raw string instead: change the DB methods to build a
`final sql = '...';` local and pass `Sql.named(sql)`, and in the test capture via a method
that also records the raw string. SIMPLER ALTERNATIVE used here: expose each method's SQL as a
top-level `const` string (mirror the existing `resetCustomWordProgressSql` pattern in
`database_reset_test.dart`) and assert against that constant. Implement the constants in Step 3.

- [ ] **Step 3: Implement the DB methods (with exported SQL constants)**

In `server/lib/src/database.dart`, add these top-level constants near the other SQL (file
scope, e.g. just above `class AppDatabase` or beside `resetCustomWordProgressSql`):

```dart
const setEmailVerifiedSql =
    'UPDATE users SET email_verified=TRUE, updated_at=@now WHERE id=@uid';

const upsertVerificationCodeSql = '''
INSERT INTO email_verification_codes (uid, code_hash, code_salt, expires_at, attempts, last_sent_at, created_at)
VALUES (@uid, @codeHash, @codeSalt, @expiresAt, 0, @sentAt, @sentAt)
ON CONFLICT (uid) DO UPDATE SET
  code_hash=@codeHash,
  code_salt=@codeSalt,
  expires_at=@expiresAt,
  attempts=0,
  last_sent_at=@sentAt
''';

const incrementVerificationAttemptsSql =
    'UPDATE email_verification_codes SET attempts=attempts+1 WHERE uid=@uid';

const deleteVerificationCodeSql =
    'DELETE FROM email_verification_codes WHERE uid=@uid';
```

Then add the methods inside `class AppDatabase` (e.g. after `userById`):

```dart
  Future<void> setEmailVerified(String uid) async {
    await connection.execute(
      Sql.named(setEmailVerifiedSql),
      parameters: {'uid': uid, 'now': DateTime.now().toUtc()},
    );
  }

  Future<void> upsertVerificationCode(
    String uid, {
    required String codeHash,
    required String codeSalt,
    required DateTime expiresAt,
    required DateTime sentAt,
  }) async {
    await connection.execute(
      Sql.named(upsertVerificationCodeSql),
      parameters: {
        'uid': uid,
        'codeHash': codeHash,
        'codeSalt': codeSalt,
        'expiresAt': expiresAt,
        'sentAt': sentAt,
      },
    );
  }

  Future<Map<String, dynamic>?> verificationCodeFor(String uid) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM email_verification_codes WHERE uid=@uid LIMIT 1'),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<void> incrementVerificationAttempts(String uid) async {
    await connection.execute(
      Sql.named(incrementVerificationAttemptsSql),
      parameters: {'uid': uid},
    );
  }

  Future<void> deleteVerificationCode(String uid) async {
    await connection.execute(
      Sql.named(deleteVerificationCodeSql),
      parameters: {'uid': uid},
    );
  }
```

Now update `server/test/email_verification_db_test.dart` to assert against the constants
(mirroring `database_reset_test.dart`): replace each `connection.lastSql` SQL-substring check
with a check against the exported constant, e.g.:

```dart
    expect(setEmailVerifiedSql, contains('UPDATE users'));
    expect(setEmailVerifiedSql, contains('email_verified=TRUE'));
    expect(setEmailVerifiedSql, contains('WHERE id=@uid'));
    expect(connection.lastParameters, {'uid': 'user-1', 'now': anything});
```
Apply the same pattern (assert constant text + `connection.lastParameters`) to the other three
methods. For `setEmailVerified`, the params include `now`; use `containsPair('uid', 'user-1')`
instead of full-map equality so the timestamp doesn't break the assertion.

- [ ] **Step 4: Run it, confirm PASS**

Run: `cd server && dart test test/email_verification_db_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Run the existing DB test to ensure nothing regressed**

Run: `cd server && dart test test/database_reset_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add server/lib/src/database.dart server/test/email_verification_db_test.dart
git commit -m "feat(server): email_verified migration + verification-code DB methods"
```

---

## Task S3: Backend register + verify endpoints

**Files:**
- Modify: `server/lib/src/routes.dart`
- Test: `server/test/auth_verification_routes_test.dart`

- [ ] **Step 1: Write the failing test (fake DB + fake email sender)**

Create `server/test/auth_verification_routes_test.dart`:

```dart
import 'dart:convert';

import 'package:linguaquest_server/src/auth.dart';
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/database.dart';
import 'package:linguaquest_server/src/email_sender.dart';
import 'package:linguaquest_server/src/routes.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
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
  test('register creates an unverified user and emails a code, no token',
      () async {
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

    final res = await _post(
        router, '/auth/verify', {'email': 'ada@lingua.quest', 'code': '000000'});
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
}

/// In-memory AppDatabase used only for these route tests.
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
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'name': name,
      'target_exam': 'HSK 1',
      'level': 'Beginner',
      'daily_goal': 10,
      'xp': 0,
      'streak': 0,
      'email_verified': false,
      'last_study_date': null,
      'created_at': now,
      'updated_at': now,
    };
  }

  @override
  Future<void> setEmailVerified(String uid) async {
    users[uid]!['email_verified'] = true;
  }

  @override
  Future<void> upsertVerificationCode(
    String uid, {
    required String codeHash,
    required String codeSalt,
    required DateTime expiresAt,
    required DateTime sentAt,
  }) async {
    codes[uid] = {
      'uid': uid,
      'code_hash': codeHash,
      'code_salt': codeSalt,
      'expires_at': expiresAt,
      'attempts': 0,
      'last_sent_at': sentAt,
      'created_at': sentAt,
    };
  }

  @override
  Future<Map<String, dynamic>?> verificationCodeFor(String uid) async =>
      codes[uid];

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
```

NOTE: `FakeEmailSender` is defined in `email_sender.dart` in Step 3 of this task (so production
code and tests share it). If you prefer not to ship a fake in production code, instead put
`FakeEmailSender` at the bottom of this test file implementing `EmailSender`.

- [ ] **Step 2: Run it, confirm FAIL**

Run: `cd server && dart test test/auth_verification_routes_test.dart`
Expected: FAIL — `buildRouter` has no `emailSender` param; `/auth/verify` missing; register still returns a token.

- [ ] **Step 3: Add `FakeEmailSender` to `email_sender.dart`**

Append to `server/lib/src/email_sender.dart`:

```dart
/// Test double that captures the last code instead of sending anything.
class FakeEmailSender implements EmailSender {
  String? lastTo;
  String? lastCode;

  @override
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  }) async {
    lastTo = to;
    lastCode = code;
  }
}
```

- [ ] **Step 4: Wire `emailSender` + helpers into `buildRouter`, change register, add verify**

In `server/lib/src/routes.dart`:

(a) Add the import at the top (after `import 'database.dart';`):
```dart
import 'email_sender.dart';
```

(b) Change `buildRouter`'s signature and resolve the sender at the top of the function:
```dart
Router buildRouter(
  AppConfig config,
  AppDatabase database, {
  http.Client? httpClient,
  EmailSender? emailSender,
}) {
  final client = httpClient ?? _httpClient;
  final mailer = emailSender ?? EmailSender.fromConfig(config);
  final router = Router();
```

(c) Add these top-level helpers at the bottom of `routes.dart` (file scope):
```dart
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

String generateOtpCode() {
  final rng = math.Random.secure();
  return (rng.nextInt(900000) + 100000).toString(); // 100000..999999
}

Future<void> _issueAndSendCode(
  AppConfig config,
  AppDatabase database,
  EmailSender mailer, {
  required String uid,
  required String email,
}) async {
  final code = generateOtpCode();
  final salt = newSalt();
  final now = DateTime.now().toUtc();
  await database.upsertVerificationCode(
    uid,
    codeHash: hashPassword(code, salt),
    codeSalt: salt,
    expiresAt: now.add(const Duration(minutes: 10)),
    sentAt: now,
  );
  await mailer.sendVerificationCode(to: email, code: code);
}
```
(`math` is already imported as `math` at the top of routes.dart.)

(d) REPLACE the existing `/auth/register` handler body with:
```dart
  router.post('/auth/register', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final name = (body['name'] as String? ?? '').trim();
    if (name.isEmpty || !isValidEmail(email) || password.length < 6) {
      return jsonResponse({
        'error': 'name, valid email, and 6+ character password are required',
      }, status: 400);
    }
    if (await database.userByEmail(email) != null) {
      return jsonResponse({'error': 'email already registered'}, status: 409);
    }
    final salt = newSalt();
    final uid = newId();
    await database.insertUser(
      id: uid,
      email: email,
      passwordHash: hashPassword(password, salt),
      passwordSalt: salt,
      name: name,
    );
    await _issueAndSendCode(config, database, mailer, uid: uid, email: email);
    return jsonResponse(
      {'status': 'verification_required', 'email': email},
      status: 202,
    );
  });
```

(e) ADD the `/auth/verify` handler (immediately after the register handler):
```dart
  router.post('/auth/verify', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final code = (body['code'] as String? ?? '').trim();
    final user = await database.userByEmail(email);
    if (user == null) {
      return jsonResponse({'error': 'invalid_code'}, status: 400);
    }
    final uid = user['id'] as String;
    if (user['email_verified'] == true) {
      return jsonResponse({
        'token': issueToken(config, uid: uid, email: email),
        'user': userDto(user),
      });
    }
    final row = await database.verificationCodeFor(uid);
    if (row == null ||
        (row['expires_at'] as DateTime).isBefore(DateTime.now().toUtc())) {
      return jsonResponse({'error': 'code_expired'}, status: 410);
    }
    if ((row['attempts'] as int) >= 5) {
      return jsonResponse({'error': 'too_many_attempts'}, status: 429);
    }
    final expected = hashPassword(code, row['code_salt'] as String);
    if (expected != row['code_hash']) {
      await database.incrementVerificationAttempts(uid);
      return jsonResponse({'error': 'invalid_code'}, status: 400);
    }
    await database.setEmailVerified(uid);
    await database.deleteVerificationCode(uid);
    final verified = await database.userById(uid);
    return jsonResponse({
      'token': issueToken(config, uid: uid, email: email),
      'user': userDto(verified!),
    });
  });
```

(f) Add `emailVerified` to `userDto` (the map literal):
```dart
    'streak': row['streak'],
    'emailVerified': row['email_verified'] ?? true,
    'lastStudyDate': (row['last_study_date'] as DateTime?)?.toIso8601String(),
```

- [ ] **Step 5: Run it, confirm PASS**

Run: `cd server && dart test test/auth_verification_routes_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add server/lib/src/routes.dart server/lib/src/email_sender.dart server/test/auth_verification_routes_test.dart
git commit -m "feat(server): register issues OTP (no token); add /auth/verify"
```

---

## Task S4: Backend login gate + resend endpoint

**Files:**
- Modify: `server/lib/src/routes.dart`
- Test: `server/test/auth_verification_routes_test.dart` (append)

- [ ] **Step 1: Append failing tests**

Add inside `main()` of `server/test/auth_verification_routes_test.dart`:

```dart
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
```

- [ ] **Step 2: Run, confirm FAIL**

Run: `cd server && dart test test/auth_verification_routes_test.dart`
Expected: FAIL — login still returns 200/401 ignoring verification; `/auth/resend` missing.

- [ ] **Step 3: Change login + add resend**

In `server/lib/src/routes.dart`, REPLACE the `/auth/login` handler with:
```dart
  router.post('/auth/login', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final user = await database.userByEmail(email);
    if (user == null) {
      return jsonResponse({'error': 'invalid email or password'}, status: 401);
    }
    final expected = hashPassword(password, user['password_salt'] as String);
    if (expected != user['password_hash']) {
      return jsonResponse({'error': 'invalid email or password'}, status: 401);
    }
    if (user['email_verified'] != true) {
      await _issueAndSendCode(
        config, database, mailer,
        uid: user['id'] as String, email: email,
      );
      return jsonResponse(
        {'error': 'email_not_verified', 'email': email},
        status: 403,
      );
    }
    return jsonResponse({
      'token': issueToken(config, uid: user['id'] as String, email: email),
      'user': userDto(user),
    });
  });
```

ADD the `/auth/resend` handler after login:
```dart
  router.post('/auth/resend', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final user = await database.userByEmail(email);
    // Don't leak account existence / verified state.
    if (user == null || user['email_verified'] == true) {
      return jsonResponse({'status': 'sent'});
    }
    final uid = user['id'] as String;
    final existing = await database.verificationCodeFor(uid);
    if (existing != null) {
      final last = existing['last_sent_at'] as DateTime;
      final elapsed = DateTime.now().toUtc().difference(last);
      if (elapsed < const Duration(seconds: 60)) {
        return jsonResponse(
          {'error': 'resend_cooldown', 'retryAfter': 60 - elapsed.inSeconds},
          status: 429,
        );
      }
    }
    await _issueAndSendCode(config, database, mailer, uid: uid, email: email);
    return jsonResponse({'status': 'sent'});
  });
```

- [ ] **Step 4: Run, confirm PASS**

Run: `cd server && dart test test/auth_verification_routes_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Run the whole server suite**

Run: `cd server && dart test`
Expected: all pass (existing + new). Fix any regression (e.g. an existing `routes_test.dart`
that registered+logged-in expecting a token — update it to register→verify→login, using a
`FakeEmailSender` to read the code).

- [ ] **Step 6: Commit**

```bash
git add server/lib/src/routes.dart server/test/auth_verification_routes_test.dart
git commit -m "feat(server): block unverified login; add /auth/resend with cooldown"
```

---

## Task C1: Client email-format validation

**Files:**
- Create: `linguaquest/lib/core/utils/email_validation.dart`
- Modify: `linguaquest/lib/features/auth/login_screen.dart`, `register_screen.dart`
- Test: `linguaquest/test/email_validation_test.dart`

- [ ] **Step 1: Write failing test**

Create `linguaquest/test/email_validation_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/email_validation.dart';

void main() {
  test('isValidEmail rejects garbled addresses', () {
    expect(isValidEmail('a@b'), isFalse);
    expect(isValidEmail('user@'), isFalse);
    expect(isValidEmail('no-at-sign'), isFalse);
    expect(isValidEmail('a b@c.com'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  test('isValidEmail accepts well-formed addresses', () {
    expect(isValidEmail('a@b.co'), isTrue);
    expect(isValidEmail('ada.lovelace@lingua.quest'), isTrue);
  });
}
```

- [ ] **Step 2: Run, confirm FAIL**

Run: `cd linguaquest && flutter test test/email_validation_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 3: Implement the util**

Create `linguaquest/lib/core/utils/email_validation.dart`:
```dart
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Mirrors the backend `isValidEmail`: requires `local@domain.tld` with no
/// whitespace. Rejects the garbled addresses that previously slipped through.
bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());
```

- [ ] **Step 4: Run, confirm PASS**

Run: `cd linguaquest && flutter test test/email_validation_test.dart`
Expected: PASS.

- [ ] **Step 5: Use it in both form validators**

In `linguaquest/lib/features/auth/login_screen.dart` AND
`linguaquest/lib/features/auth/register_screen.dart`, add the import:
```dart
import '../../core/utils/email_validation.dart';
```
and replace the `_emailValidator` body's `@` check:
```dart
String? _emailValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.authEmailRequired;
  if (!isValidEmail(value)) return l10n.authEmailInvalid;
  return null;
}
```

- [ ] **Step 6: Analyze + commit**

Run: `cd linguaquest && flutter analyze lib/core/utils/email_validation.dart lib/features/auth`
Expected: `No issues found!`
```bash
git add linguaquest/lib/core/utils/email_validation.dart linguaquest/lib/features/auth/login_screen.dart linguaquest/lib/features/auth/register_screen.dart linguaquest/test/email_validation_test.dart
git commit -m "feat(auth): strict email-format validation on login/register forms"
```

---

## Task C2: `UserProfile.emailVerified`

**Files:**
- Modify: `linguaquest/lib/data/models/user_profile.dart`
- Test: `linguaquest/test/user_profile_verified_test.dart`

- [ ] **Step 1: Write failing test**

Create `linguaquest/test/user_profile_verified_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/user_profile.dart';

void main() {
  test('emailVerified defaults to true and round-trips through JSON', () {
    final base = UserProfile.demo();
    expect(base.emailVerified, isTrue);

    final fromBackend = UserProfile.fromJson({
      ...base.toJson(),
      'emailVerified': false,
    });
    expect(fromBackend.emailVerified, isFalse);
    expect(fromBackend.toJson()['emailVerified'], isFalse);
    expect(base.copyWith(emailVerified: false).emailVerified, isFalse);
  });
}
```

- [ ] **Step 2: Run, confirm FAIL**

Run: `cd linguaquest && flutter test test/user_profile_verified_test.dart`
Expected: FAIL — no `emailVerified`.

- [ ] **Step 3: Add the field**

In `linguaquest/lib/data/models/user_profile.dart`:
- Constructor: add `this.emailVerified = true,` (after `this.lastStudyDate,`).
- Field: add `final bool emailVerified;` (after `final DateTime updatedAt;`).
- `fromJson`: add `emailVerified: json['emailVerified'] as bool? ?? true,` (after `streak:`).
- `toJson`: add `'emailVerified': emailVerified,` (after `'streak': streak,`).
- `copyWith`: add param `bool? emailVerified,` and pass `emailVerified: emailVerified ?? this.emailVerified,`.
- `UserProfile.demo()`: no change (defaults to `true`).

- [ ] **Step 4: Run, confirm PASS**

Run: `cd linguaquest && flutter test test/user_profile_verified_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/data/models/user_profile.dart linguaquest/test/user_profile_verified_test.dart
git commit -m "feat(model): UserProfile.emailVerified (default true)"
```

---

## Task C3: `AuthRepository` contract (results + exceptions)

**Files:**
- Modify: `linguaquest/lib/data/repositories/auth_repository.dart`

- [ ] **Step 1: Replace the interface file**

Replace `linguaquest/lib/data/repositories/auth_repository.dart` entirely:
```dart
import '../models/user_profile.dart';

/// Result of a registration attempt.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.profile);
  final UserProfile profile;
}

class AuthVerificationRequired extends AuthResult {
  const AuthVerificationRequired(this.email);
  final String email;
}

/// Thrown by [AuthRepository.login] when the account exists but is unverified.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException(this.email);
  final String email;
}

/// Thrown by [AuthRepository.verifyEmail] for code problems. [reason] is one of
/// 'invalid_code', 'code_expired', 'too_many_attempts'.
class EmailVerificationException implements Exception {
  const EmailVerificationException(this.reason);
  final String reason;
}

abstract class AuthRepository {
  Future<UserProfile?> loadSession();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserProfile> login({required String email, required String password});

  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  });

  Future<void> resendCode(String email);

  Future<UserProfile> updateProfile(UserProfile profile);

  Future<void> logout();
}
```

- [ ] **Step 2: Analyze (expect errors in the impls — fixed in C4/C5)**

Run: `cd linguaquest && flutter analyze lib/data/repositories/auth_repository.dart`
Expected: `No issues found!` for this file (the impls will now fail to compile until C4/C5;
that's expected — do not run the full analyze yet).

- [ ] **Step 3: Commit**

```bash
git add linguaquest/lib/data/repositories/auth_repository.dart
git commit -m "feat(auth): AuthResult/exception contract for verification"
```

---

## Task C4: `ApiAuthRepository` against new endpoints

**Files:**
- Modify: `linguaquest/lib/data/repositories/api_repositories.dart`

- [ ] **Step 1: Replace register/login + add verifyEmail/resendCode**

In `linguaquest/lib/data/repositories/api_repositories.dart`, ensure the auth import is present
at the top (it already imports the repositories barrel; add if missing):
```dart
import 'auth_repository.dart';
```
Add `import 'package:dio/dio.dart';` if not already imported (it is used by ApiClient).

Replace `ApiAuthRepository.register` with:
```dart
  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    final data = response.data!;
    if (data['status'] == 'verification_required') {
      return AuthVerificationRequired(data['email'] as String? ?? email);
    }
    return AuthSuccess(await _saveAuthResponse(data));
  }
```

Replace `ApiAuthRepository.login` with:
```dart
  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _saveAuthResponse(response.data!);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode == 403 &&
          data is Map &&
          data['error'] == 'email_not_verified') {
        throw EmailNotVerifiedException(
          data['email'] as String? ?? email,
        );
      }
      rethrow;
    }
  }
```

Add (after login, before updateProfile):
```dart
  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/verify',
        data: {'email': email, 'code': code},
      );
      return _saveAuthResponse(response.data!);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        throw EmailVerificationException(data['error'] as String);
      }
      rethrow;
    }
  }

  @override
  Future<void> resendCode(String email) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/auth/resend',
      data: {'email': email},
    );
  }
```

(`dio` must not throw on 202: dio's default `validateStatus` treats 2xx as success, so register's
202 is fine.)

- [ ] **Step 2: Analyze**

Run: `cd linguaquest && flutter analyze lib/data/repositories/api_repositories.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add linguaquest/lib/data/repositories/api_repositories.dart
git commit -m "feat(auth): ApiAuthRepository verify/resend + verification-aware register/login"
```

---

## Task C5: `MockAuthRepository` (offline) verification behavior

**Files:**
- Modify: `linguaquest/lib/data/repositories/mock_repositories.dart`
- Test: `linguaquest/test/mock_auth_verification_test.dart`

- [ ] **Step 1: Write failing test**

Create `linguaquest/test/mock_auth_verification_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('register rejects a garbled email', () async {
    final repo = MockAuthRepository();
    expect(
      () => repo.register(name: 'A', email: 'a@b', password: 'secret1'),
      throwsA(isA<StateError>()),
    );
  });

  test('register returns verified success for a valid email', () async {
    final repo = MockAuthRepository();
    final result = await repo.register(
      name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    expect(result, isA<AuthSuccess>());
    expect((result as AuthSuccess).profile.emailVerified, isTrue);
  });

  test('login fails for an unregistered email', () async {
    final repo = MockAuthRepository();
    expect(
      () => repo.login(email: 'nobody@lingua.quest', password: 'secret1'),
      throwsA(isA<StateError>()),
    );
  });

  test('login succeeds after register', () async {
    final repo = MockAuthRepository();
    await repo.register(
      name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    final profile = await repo.login(
      email: 'ada@lingua.quest', password: 'secret1');
    expect(profile.email, 'ada@lingua.quest');
  });
}
```

- [ ] **Step 2: Run, confirm FAIL**

Run: `cd linguaquest && flutter test test/mock_auth_verification_test.dart`
Expected: FAIL — register returns `UserProfile` (not `AuthResult`); login fabricates a user.

- [ ] **Step 3: Update `MockAuthRepository`**

In `linguaquest/lib/data/repositories/mock_repositories.dart`, add the import:
```dart
import '../../core/utils/email_validation.dart';
```
Replace `register` (return type + body) with:
```dart
  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isValidEmail(normalizedEmail)) {
      throw StateError('invalid email');
    }
    final prefs = await SharedPreferences.getInstance();
    final registeredEmails =
        prefs.getStringList(_registeredEmailsKey) ?? const <String>[];
    final normalizedRegisteredEmails = registeredEmails
        .map((email) => email.trim().toLowerCase())
        .toSet();
    if (normalizedRegisteredEmails.contains(normalizedEmail)) {
      throw StateError('email already registered');
    }
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'user-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      targetExam: 'HSK 1',
      level: 'Beginner',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    await prefs.setStringList(_registeredEmailsKey, [
      ...normalizedRegisteredEmails,
      normalizedEmail,
    ]);
    return AuthSuccess(await updateProfile(profile));
  }
```
Replace `login` with (require prior registration; no fabricated user):
```dart
  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isValidEmail(normalizedEmail)) {
      throw StateError('invalid email');
    }
    final prefs = await SharedPreferences.getInstance();
    final registered = (prefs.getStringList(_registeredEmailsKey) ?? const [])
        .map((e) => e.trim().toLowerCase())
        .toSet();
    final existing = await loadSession();
    if (existing != null && existing.email == normalizedEmail) {
      return existing;
    }
    if (!registered.contains(normalizedEmail)) {
      throw StateError('account not found');
    }
    final profile = UserProfile.demo().copyWith(
      email: normalizedEmail,
      updatedAt: DateTime.now(),
    );
    return updateProfile(profile);
  }
```
Add the two new no-op methods (offline has no mail server):
```dart
  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) async {
    final existing = await loadSession();
    if (existing != null) return existing;
    return login(email: email, password: '');
  }

  @override
  Future<void> resendCode(String email) async {}
```

- [ ] **Step 4: Run, confirm PASS**

Run: `cd linguaquest && flutter test test/mock_auth_verification_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/data/repositories/mock_repositories.dart linguaquest/test/mock_auth_verification_test.dart
git commit -m "feat(auth): offline mock enforces email format + register-before-login"
```

---

## Task C6: `AppController` verification flow

**Files:**
- Modify: `linguaquest/lib/core/state/app_controller.dart`

- [ ] **Step 1: Add the `AuthStep` enum**

At the top of `linguaquest/lib/core/state/app_controller.dart` (after the imports, before the
provider/class — place it at file scope):
```dart
/// Outcome of a register/login attempt, used by the auth screens to decide
/// navigation (home vs the verify-email screen vs showing an error).
enum AuthStep { authenticated, needsVerification, failed }
```
Ensure the auth-result types are imported (the controller already imports the repositories;
add if missing):
```dart
import '../../data/repositories/auth_repository.dart';
```

- [ ] **Step 2: Extract the post-auth hydration helper**

Add this private method to the controller class (near `_ensureStudyPlan`):
```dart
  Future<void> _applyAuthenticatedUser(UserProfile user) async {
    final lotteryData = await _loadLotteryData(user);
    state = state.copyWith(
      user: user,
      customWords: await _customWordRepository.list(user.uid),
      lotteryPrizes: lotteryData.prizes,
      userAssets: lotteryData.assets,
      userWords: await _userWordRepository.list(user.uid),
    );
    await _ensureStudyPlan(user);
    await refreshNotifications();
    await refreshRewardTasks();
    unawaited(_scheduleLocalNotifications());
  }
```

- [ ] **Step 3: Replace `register` and `login`**

Replace the existing `register` method with:
```dart
  Future<AuthStep> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      if (result is AuthVerificationRequired) {
        state = state.copyWith(isLoading: false);
        return AuthStep.needsVerification;
      }
      await _applyAuthenticatedUser((result as AuthSuccess).profile);
      state = state.copyWith(isLoading: false);
      return AuthStep.authenticated;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return AuthStep.failed;
    }
  }
```
Replace the existing `login` method with:
```dart
  Future<AuthStep> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user =
          await _authRepository.login(email: email, password: password);
      await _applyAuthenticatedUser(user);
      state = state.copyWith(isLoading: false);
      return AuthStep.authenticated;
    } on EmailNotVerifiedException {
      state = state.copyWith(isLoading: false);
      return AuthStep.needsVerification;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return AuthStep.failed;
    }
  }
```

- [ ] **Step 4: Add `verifyEmail` and `resendCode`**

Add (near login):
```dart
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user =
          await _authRepository.verifyEmail(email: email, code: code);
      await _applyAuthenticatedUser(user);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<void> resendCode(String email) async {
    try {
      await _authRepository.resendCode(email);
    } catch (_) {
      // Best-effort; the screen shows its own cooldown feedback.
    }
  }
```

- [ ] **Step 5: Analyze**

Run: `cd linguaquest && flutter analyze lib/core/state/app_controller.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add linguaquest/lib/core/state/app_controller.dart
git commit -m "feat(auth): AppController register/login return AuthStep; add verifyEmail/resendCode"
```

---

## Task C7: Verify-email screen + routing + screen navigation

**Files:**
- Create: `linguaquest/lib/features/auth/verify_email_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart`, `login_screen.dart`, `register_screen.dart`

- [ ] **Step 1: Create the verify screen**

Create `linguaquest/lib/features/auth/verify_email_screen.dart`:
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    final ok = await ref
        .read(appControllerProvider.notifier)
        .verifyEmail(email: widget.email, code: code);
    if (!mounted) return;
    if (ok) context.go('/home');
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    await ref.read(appControllerProvider.notifier).resendCode(widget.email);
    if (!mounted) return;
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = ref.watch(
      appControllerProvider.select((s) => s.errorMessage),
    );
    final loading = ref.watch(
      appControllerProvider.select((s) => s.isLoading),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter the 6-digit code', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    'We sent a code to ${widget.email}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTokens.s16),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '------',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppTokens.s8),
                    Text(error, style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            AppPrimaryButton(
              onPressed: loading ? null : _submit,
              label: 'Verify',
            ),
            const SizedBox(height: AppTokens.s8),
            TextButton(
              onPressed: _cooldown > 0 ? null : _resend,
              child: Text(
                _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
NOTE: confirm `AppPrimaryButton`'s parameter names (`onPressed`/`label`) by checking
`lib/core/widgets/app_button.dart`; adapt if they differ (e.g. `onTap`/`text`).

- [ ] **Step 2: Register the route**

In `linguaquest/lib/core/routing/app_router.dart`, add the import:
```dart
import '../../features/auth/verify_email_screen.dart';
```
and add a route between `/register` and `/goal-setup`:
```dart
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
```

- [ ] **Step 3: Update the register screen navigation**

In `linguaquest/lib/features/auth/register_screen.dart`, replace the `_submit` body's call/branch:
```dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final step = await ref.read(appControllerProvider.notifier).register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    switch (step) {
      case AuthStep.needsVerification:
        context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
      case AuthStep.authenticated:
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authAccountCreated)),
        );
        context.go('/goal-setup');
      case AuthStep.failed:
        break;
    }
  }
```
Add the import `import '../../core/state/app_controller.dart';` if `AuthStep` isn't resolved
(the screen already reads `appControllerProvider`, so the import is present).

- [ ] **Step 4: Update the login screen navigation**

In `linguaquest/lib/features/auth/login_screen.dart`, replace `_submit`:
```dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final step = await ref
        .read(appControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    if (!mounted) return;
    switch (step) {
      case AuthStep.authenticated:
        context.go('/home');
      case AuthStep.needsVerification:
        context.go('/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}');
      case AuthStep.failed:
        break;
    }
  }
```

- [ ] **Step 5: Analyze**

Run: `cd linguaquest && flutter analyze lib/features/auth lib/core/routing/app_router.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add linguaquest/lib/features/auth/verify_email_screen.dart linguaquest/lib/core/routing/app_router.dart linguaquest/lib/features/auth/login_screen.dart linguaquest/lib/features/auth/register_screen.dart
git commit -m "feat(auth): verify-email OTP screen + route unverified register/login into it"
```

---

## Task C8: Full verification gate

**Files:** possibly any test that asserted the old `login`/`register` `bool` return or
fabricated-user mock behavior.

- [ ] **Step 1: Server suite**

Run: `cd server && dart test`
Expected: all pass. (Paste output.)

- [ ] **Step 2: App analyze**

Run: `cd linguaquest && flutter analyze`
Expected: `No issues found!` Fix any straggler (e.g. a test/screen still treating
`controller.login(...)` as `Future<bool>` — update to `AuthStep`).

- [ ] **Step 3: App tests**

Run: `cd linguaquest && flutter test`
Expected: all pass. For each failure:
- Tests calling `controller.register/login` expecting `bool` → update to `AuthStep`.
- Tests using `MockAuthRepository.login` with an unregistered email → register first.
Do NOT weaken assertions; update them to the new contract. Paste the final summary.

- [ ] **Step 4: Commit any test repairs**

```bash
git add -A
git commit -m "test: update suite for email-verification auth contract"
```

- [ ] **Step 5: Manual smoke (optional)**

Start backend (`cd server && docker compose up --build`), run app against it
(`cd linguaquest && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`). Register →
the server console prints `[email] verification code for ...: NNNNNN` → enter it → lands home.
Try logging in before verifying → routed to verify screen.

---

## Self-review notes (author)

- **Spec coverage:** §1 schema → S2; §2 EmailSender → S1; §3 endpoints → S3/S4; §4 client
  (validation/model/repo/screen/routing) → C1–C7; §5 error handling → C4 (exception mapping) +
  verify screen; §6 testing → S1–S4, C1/C2/C5, C8. Migration-backfill decision → S2 Step 1.
- **Type consistency:** `AuthResult`/`AuthSuccess`/`AuthVerificationRequired`,
  `EmailNotVerifiedException`, `EmailVerificationException`, `AuthStep`, `emailVerified`,
  `verifyEmail({email,code})`, `resendCode(email)`, `isValidEmail`, `_applyAuthenticatedUser`,
  `_issueAndSendCode`, `generateOtpCode` used consistently across tasks.
- **Known follow-ups (non-goals):** password reset, magic links, OAuth; ARB stays frozen
  (verify screen uses English literals).
- **Watch-outs flagged inline:** `Sql.toString()` may not expose raw text → S2 exports SQL
  constants instead; `AppPrimaryButton` param names → verify in C7; existing `routes_test.dart`
  may need register→verify→login update → S4 Step 5.
