# Resend OTP Email Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver OTP verification codes via the Resend HTTP API so the existing email-verification flow actually reaches users' inboxes.

**Architecture:** Add a `ResendEmailSender implements EmailSender` (using `package:http`, injectable client) alongside the existing senders in `server/lib/src/email_sender.dart`. Add `RESEND_API_KEY` + `MAIL_FROM` config. `EmailSender.fromConfig` gains a three-level priority: Resend → SMTP → Console. OTP generation/validation/routes are untouched.

**Tech Stack:** Dart, `shelf`, `package:http` (already a dependency, `^1.2.0`), `package:http/testing.dart` (`MockClient`), `package:test`.

## Global Constraints

- Work only in `server/`. Do **not** modify the Flutter app.
- Do **not** change OTP generation/validation/cooldown logic or any `/auth/*` route handler.
- Do **not** change the existing `SmtpEmailSender` or the SMTP config path.
- Backward compatible: with no `RESEND_API_KEY` set, behavior is identical to today.
- The real `RESEND_API_KEY` goes only into `server/.env` (git-ignored, confirmed via `git check-ignore .env`). `.env.example` gets empty placeholders only — never a real key.
- `EmailSender.sendVerificationCode` signature is fixed: `Future<void> sendVerificationCode({required String to, required String code})`.
- Run all commands from inside `server/`.

---

### Task 1: ResendEmailSender + config fields + factory selection

**Files:**
- Modify: `server/lib/src/config.dart` (add `resendApiKey`, `mailFrom` fields + env reads)
- Modify: `server/lib/src/email_sender.dart` (add imports, `ResendEmailSender` class, update `EmailSender.fromConfig`)
- Test: `server/test/resend_email_sender_test.dart` (create)

**Interfaces:**
- Consumes: `AppConfig` (gains `String resendApiKey`, `String mailFrom`), `EmailSender` interface from `email_sender.dart`.
- Produces:
  - `AppConfig.resendApiKey` (`String`, default `''`), `AppConfig.mailFrom` (`String`, default `'no-reply@linguaquest.app'`).
  - `ResendEmailSender(AppConfig config, {http.Client? client})` with method `Future<void> sendVerificationCode({required String to, required String code})`.
  - `EmailSender.fromConfig(AppConfig)` now returns `ResendEmailSender` when `resendApiKey` is non-empty.

- [ ] **Step 1: Add config fields**

In `server/lib/src/config.dart`, add the two fields to the const constructor (after `smtpFrom`, line 12), the field declarations (after `smtpFrom`, line 27), and the env reads in `fromEnvironment` (after `smtpFrom`, line 46).

Constructor — add after `this.smtpFrom = 'no-reply@linguaquest.app',`:

```dart
    this.resendApiKey = '',
    this.mailFrom = 'no-reply@linguaquest.app',
```

Field declarations — add after `final String smtpFrom;`:

```dart
  final String resendApiKey;
  final String mailFrom;
```

`fromEnvironment` — add after `smtpFrom: _env('SMTP_FROM', 'no-reply@linguaquest.app'),`:

```dart
      resendApiKey: _env('RESEND_API_KEY', ''),
      mailFrom: _env('MAIL_FROM', 'no-reply@linguaquest.app'),
```

- [ ] **Step 2: Write the failing test**

Create `server/test/resend_email_sender_test.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/email_sender.dart';
import 'package:test/test.dart';

const _base = AppConfig(port: 0, databaseUrl: 'x', jwtSecret: 'y');

void main() {
  test('posts a correct request to the Resend API', () async {
    http.Request? captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response('{"id":"email_123"}', 200);
    });
    final config = _base.copyWith(
      resendApiKey: 're_test_key',
      mailFrom: 'no-reply@vonlan233.top',
    );
    final sender = ResendEmailSender(config, client: client);

    await sender.sendVerificationCode(to: 'user@example.com', code: '123456');

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.toString(), 'https://api.resend.com/emails');
    expect(captured!.headers['Authorization'], 'Bearer re_test_key');
    expect(captured!.headers['Content-Type'], contains('application/json'));
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['from'], 'no-reply@vonlan233.top');
    expect(body['to'], ['user@example.com']);
    expect(body['subject'], 'Your LinguaQuest verification code');
    expect(body['text'], contains('123456'));
  });

  test('does not throw on a 2xx response', () async {
    final client = MockClient((req) async => http.Response('{"id":"x"}', 200));
    final sender = ResendEmailSender(
      _base.copyWith(resendApiKey: 're_test_key'),
      client: client,
    );
    await sender.sendVerificationCode(to: 'a@b.com', code: '654321');
  });

  test('throws with the status code on a non-2xx response', () async {
    final client = MockClient(
      (req) async => http.Response('{"message":"invalid from"}', 422),
    );
    final sender = ResendEmailSender(
      _base.copyWith(resendApiKey: 're_test_key'),
      client: client,
    );
    expect(
      () => sender.sendVerificationCode(to: 'a@b.com', code: '654321'),
      throwsA(predicate((e) => e.toString().contains('422'))),
    );
  });

  group('EmailSender.fromConfig selection', () {
    test('returns ResendEmailSender when resendApiKey is set', () {
      final sender = EmailSender.fromConfig(
        _base.copyWith(resendApiKey: 're_x', smtpHost: 'smtp.example.com'),
      );
      expect(sender, isA<ResendEmailSender>());
    });

    test('returns SmtpEmailSender when only smtpHost is set', () {
      final sender =
          EmailSender.fromConfig(_base.copyWith(smtpHost: 'smtp.example.com'));
      expect(sender, isA<SmtpEmailSender>());
    });

    test('returns ConsoleEmailSender when neither is set', () {
      final sender = EmailSender.fromConfig(_base);
      expect(sender, isA<ConsoleEmailSender>());
    });
  });
}
```

This test uses `_base.copyWith(...)`. `AppConfig` has no `copyWith` today — Step 3 adds it.

- [ ] **Step 3: Add `copyWith` to AppConfig (test support, also generally useful)**

In `server/lib/src/config.dart`, add this method to the `AppConfig` class body (after the `fromEnvironment` factory, before the closing brace of the class):

```dart
  AppConfig copyWith({
    int? port,
    String? databaseUrl,
    String? jwtSecret,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? smtpFrom,
    String? resendApiKey,
    String? mailFrom,
    String? aiProvider,
    String? aiApiKey,
    String? aiApiBaseUrl,
    String? aiModel,
    int? aiDailyLimitPerUser,
  }) {
    return AppConfig(
      port: port ?? this.port,
      databaseUrl: databaseUrl ?? this.databaseUrl,
      jwtSecret: jwtSecret ?? this.jwtSecret,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
      resendApiKey: resendApiKey ?? this.resendApiKey,
      mailFrom: mailFrom ?? this.mailFrom,
      aiProvider: aiProvider ?? this.aiProvider,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiApiBaseUrl: aiApiBaseUrl ?? this.aiApiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      aiDailyLimitPerUser: aiDailyLimitPerUser ?? this.aiDailyLimitPerUser,
    );
  }
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `dart test test/resend_email_sender_test.dart`
Expected: FAIL — compile error, `ResendEmailSender` is not defined in `email_sender.dart`.

- [ ] **Step 5: Implement `ResendEmailSender` and update the factory**

In `server/lib/src/email_sender.dart`:

(a) Add imports at the top (after the existing `import 'dart:io';`):

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
```

(b) Replace the existing factory body (lines 16-19) so Resend takes priority:

```dart
  factory EmailSender.fromConfig(AppConfig config) {
    if (config.resendApiKey.trim().isNotEmpty) return ResendEmailSender(config);
    if (config.smtpHost.trim().isEmpty) return ConsoleEmailSender();
    return SmtpEmailSender(config);
  }
```

(c) Add the new class (place it after `SmtpEmailSender`, before `FakeEmailSender`):

```dart
/// Real delivery via the Resend HTTP API, used when RESEND_API_KEY is set.
class ResendEmailSender implements EmailSender {
  ResendEmailSender(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  final AppConfig _config;
  final http.Client _client;

  @override
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  }) async {
    final res = await _client.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer ${_config.resendApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': _config.mailFrom,
        'to': [to],
        'subject': 'Your LinguaQuest verification code',
        'text': 'Your verification code is $code. It expires in 10 minutes.',
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Resend send failed: ${res.statusCode} ${res.body}',
      );
    }
  }
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `dart test test/resend_email_sender_test.dart`
Expected: PASS — all 6 tests green.

- [ ] **Step 7: Static analysis**

Run: `dart analyze lib/src/email_sender.dart lib/src/config.dart test/resend_email_sender_test.dart`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add server/lib/src/config.dart server/lib/src/email_sender.dart server/test/resend_email_sender_test.dart
git commit -m "feat(otp): add ResendEmailSender + config + factory selection"
```

---

### Task 2: Wire environment variables + regression

**Files:**
- Modify: `server/.env` (git-ignored; add real key + from address)
- Modify: `server/.env.example` (add placeholders + comments)

**Interfaces:**
- Consumes: `RESEND_API_KEY`, `MAIL_FROM` env reads added in Task 1.
- Produces: nothing new for later tasks; enables Resend at runtime.

- [ ] **Step 1: Add placeholders to `.env.example`**

In `server/.env.example`, immediately after the existing SMTP block (after the `SMTP_FROM=...` line), add:

```bash
# Resend HTTP API (set RESEND_API_KEY to send real OTP emails; takes priority over SMTP)
RESEND_API_KEY=
# From address for OTP emails (must be a Resend-verified domain), e.g. no-reply@yourdomain.com
MAIL_FROM=no-reply@linguaquest.app
```

- [ ] **Step 2: Add real values to `.env`**

In `server/.env`, immediately after the existing `SMTP_FROM=...` line, add (the real key is provided by the operator out-of-band; do not hard-code a fabricated one):

```bash
# Resend HTTP API
RESEND_API_KEY=re_your_real_key_here
MAIL_FROM=no-reply@vonlan233.top
```

> Note: `.env` is git-ignored, so this is NOT committed. Replace `re_your_real_key_here` with the actual `re_...` key from the Resend dashboard.

- [ ] **Step 3: Verify `.env` is still ignored**

Run: `git check-ignore .env`
Expected: prints `.env` (confirming it will not be committed).

- [ ] **Step 4: Run the full server test suite (regression)**

Run: `dart test`
Expected: all tests pass, including `test/auth_verification_routes_test.dart` and `test/email_verification_db_test.dart` (which use `FakeEmailSender` and are unaffected) plus the new `test/resend_email_sender_test.dart`.

- [ ] **Step 5: Full static analysis**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add server/.env.example
git commit -m "chore(otp): document RESEND_API_KEY + MAIL_FROM in .env.example"
```

> Only `.env.example` is committed; `.env` is intentionally excluded by `.gitignore`.

---

### Task 3: Real delivery verification (manual — requires verified domain + key)

This task is **manual** and **gated on external state**: the operator must have
finished Resend DNS verification for `vonlan233.top` and put the real
`RESEND_API_KEY` + `MAIL_FROM=no-reply@vonlan233.top` into `server/.env`. No
code changes. It produces the final acceptance evidence.

- [ ] **Step 1: Confirm the domain is Verified in the Resend dashboard** (DKIM TXT `resend._domainkey`, SPF MX `send`, SPF TXT `send`, optional DMARC `_dmarc` all green).

- [ ] **Step 2: Start the server with the env loaded**

Run (from `server/`):
```bash
docker compose up --build
```
Expected: API listening on `:8080`, Postgres on `:5432`.

- [ ] **Step 3: Register to trigger a real send**

Run (use a real inbox you control as the email):
```bash
curl -i -X POST http://localhost:8080/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test","email":"YOUR_REAL_INBOX@example.com","password":"secret1"}'
```
Expected: `HTTP/1.1 202` with body `{"status":"verification_required","email":"your_real_inbox@example.com"}`. A verification email arrives in the inbox within a minute.

- [ ] **Step 4: Verify with the received code (close the loop)**

Run (replace `CODE` with the 6-digit code from the email):
```bash
curl -i -X POST http://localhost:8080/auth/verify \
  -H 'Content-Type: application/json' \
  -d '{"email":"YOUR_REAL_INBOX@example.com","code":"CODE"}'
```
Expected: `HTTP/1.1 200` with a JSON body containing a non-empty `token` and `user.emailVerified: true`.

- [ ] **Step 5: Record evidence** — paste the 202 response, inbox screenshot/confirmation, and the 200 verify response. The OTP send feature is now live.
```
