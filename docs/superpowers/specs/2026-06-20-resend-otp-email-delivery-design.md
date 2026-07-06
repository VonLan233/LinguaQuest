# Resend OTP Email Delivery — Design

**Date:** 2026-06-20
**Status:** Approved (brainstorming complete, pending spec review)
**Author:** Claude (with VonLan233)

## Problem

The OTP (one-time verification code) flow is fully implemented end to end — code
generation, salted-hash storage, route registration (`/auth/register`,
`/auth/verify`, `/auth/resend`, `/auth/login`), attempt limiting, and resend
cooldown all work. But **no email is ever actually delivered**.

Root cause: `server/.env` has `SMTP_HOST=` empty, so
`EmailSender.fromConfig` (`server/lib/src/email_sender.dart:16-19`) returns
`ConsoleEmailSender`, which only prints the code to server stdout:

```dart
stdout.writeln('[email] verification code for $to: $code');
```

Users register/login, the code is stored in the DB, but the verification code
only lands in server logs — never in the user's inbox. Hence "the send-OTP
feature isn't live."

## Goal & Scope

Add a **Resend HTTP API** email sender so OTP codes are really delivered,
gated by an environment variable. Use the existing Resend free tier
(3,000/month, 100/day, no credit card) with the user's own verified domain
`vonlan233.top`.

**In scope:**
- A new `ResendEmailSender implements EmailSender` using `package:http`.
- Two new config fields (`RESEND_API_KEY`, `MAIL_FROM`).
- Three-level sender selection in `EmailSender.fromConfig`.
- Unit tests (no network) + factory selection tests + real integration verification.

**Out of scope (do NOT touch):**
- OTP generation / validation / cooldown / attempt-limit logic.
- The four `/auth/*` routes (their error behavior is already correct).
- The existing `SmtpEmailSender` / SMTP config path.
- SMS delivery (email only).

## Architecture

### Component: `ResendEmailSender` (new)

Location: `server/lib/src/email_sender.dart` (alongside the existing senders).

```dart
class ResendEmailSender implements EmailSender {
  ResendEmailSender(this._config, {http.Client? client})
      : _client = client ?? http.Client();

  final AppConfig _config;
  final http.Client _client;

  @override
  Future<void> sendVerificationCode({required String to, required String code}) async {
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
      throw Exception('Resend send failed: ${res.statusCode} ${res.body}');
    }
  }
}
```

- `http.Client` is **injectable** so unit tests use a `MockClient` and never
  hit the network. Default is a real client.
- Single, clear responsibility: POST the code to Resend. Dependencies are only
  `AppConfig` + `http.Client`. Independently testable.
- On non-2xx it throws (message carries status code + body for prod debugging),
  matching `SmtpEmailSender`'s "throw on failure" behavior.

### Config changes

`server/lib/src/config.dart` gains two fields:

| env var | config field | default | purpose |
|---|---|---|---|
| `RESEND_API_KEY` | `resendApiKey` | `''` | the `re_...` key; non-empty enables Resend |
| `MAIL_FROM` | `mailFrom` | `'no-reply@linguaquest.app'` | sender address; will be set to `no-reply@vonlan233.top` |

`MAIL_FROM` is a new neutral field rather than reusing the SMTP-specific
`SMTP_FROM`, keeping the SMTP path untouched (no unrelated refactor). Mild
duplication of "from" is accepted in exchange for clear boundaries and zero risk
to the SMTP path.

### Factory selection (three-level priority)

`EmailSender.fromConfig` (`email_sender.dart:16-19`) becomes:

```dart
factory EmailSender.fromConfig(AppConfig config) {
  if (config.resendApiKey.trim().isNotEmpty) return ResendEmailSender(config);
  if (config.smtpHost.trim().isNotEmpty) return SmtpEmailSender(config);
  return ConsoleEmailSender();
}
```

Resend if its key is set; else SMTP if its host is set; else Console (dev
stdout). Backward compatible — existing deployments without a Resend key behave
exactly as before.

## Data flow (unchanged routes)

`/auth/register` (and `/auth/login` for unverified, `/auth/resend`) call
`_issueAndSendCode` (`routes.dart:1939`), which stores the salted-hash code then
calls `mailer.sendVerificationCode`. With Resend selected, that POST goes to the
Resend API and the user receives a real email. **No route code changes.**

## Error handling

The `/auth/*` routes have no try/catch around `_issueAndSendCode`, so a thrown
send error becomes a 500 — identical to today's `SmtpEmailSender` behavior. We
keep this. Note `/auth/register` inserts the user *before* sending; if delivery
fails, the user exists but got no code and can retry via the existing
`/auth/resend`. This is pre-existing behavior and is not changed here.

## Security

- The real `RESEND_API_KEY` goes only into `server/.env`, which is confirmed
  git-ignored (`git check-ignore .env` → `.env`).
- `.env.example` gets only an empty placeholder `RESEND_API_KEY=` with a comment
  and `MAIL_FROM=` with the default, never a real key.

## Testing strategy

**Unit — `server/test/resend_email_sender_test.dart` (new, no network):**
Inject `MockClient` from `package:http/testing.dart` and assert:
1. Request correctness: URL `https://api.resend.com/emails`; headers include
   `Authorization: Bearer <key>` and `Content-Type: application/json`; JSON body
   has correct `from` (= `mailFrom`), `to` (= `[recipient]`), `subject`, and
   `text` containing the 6-digit code.
2. Success path: mock returns 200 → no throw.
3. Failure path: mock returns 422/401 → throws, message contains the status code.

**Factory selection test:** `resendApiKey` set → `ResendEmailSender`; only
`smtpHost` set → `SmtpEmailSender`; neither → `ConsoleEmailSender`.

**Regression:** run existing `server/test/auth_verification_routes_test.dart`
and `email_verification_db_test.dart` to confirm the `FakeEmailSender`-based
flows still pass.

**Real integration (final acceptance evidence):**
1. Verify `vonlan233.top` DNS (SPF/DKIM) in the Resend dashboard.
2. Put the real `RESEND_API_KEY` and `MAIL_FROM=no-reply@vonlan233.top` in `.env`.
3. Start server → `curl POST /auth/register` → real verification email received
   → paste HTTP 202 response + inbox confirmation.
4. `curl POST /auth/verify` with the received code → JWT returned. Loop closed.

## Files touched

- `server/lib/src/email_sender.dart` — add `ResendEmailSender`, update factory.
- `server/lib/src/config.dart` — add `resendApiKey`, `mailFrom` + env reads.
- `server/.env` — add real `RESEND_API_KEY`, `MAIL_FROM` (git-ignored).
- `server/.env.example` — add placeholders + comments.
- `server/test/resend_email_sender_test.dart` — new unit tests.
- (factory selection test: new or appended to existing email test.)
