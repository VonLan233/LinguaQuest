# Design: Email verification (OTP, block-until-verified)

**Date:** 2026-06-19
**Branch:** `feat/P1-2-Chinese-Login` (off `dev`)
**Status:** Approved design → ready for implementation plan
**Feature 1 of 2** (the other, cross-device progress sync, gets its own spec on `feat/P1-2-Online_check-Sync`).

## Goal

Make account email verification *thorough*: a user must prove ownership of their email
(via a 6-digit code) before they can use the account. Today the backend issues a JWT
immediately on register with **no verification**, validation is only "contains `@`", and
offline/mock mode logs in with literally any string — so garbled emails work. This feature
adds real email-format validation, a one-time-code verification step, and blocks unverified
accounts from logging in.

## Decisions (locked via brainstorming)

- **Build order:** this (email verification) first; cross-device sync second.
- **Email delivery:** pluggable `EmailSender` — real SMTP (env-configured) with an automatic
  dev-console fallback that logs the code when SMTP is not configured.
- **Proof of ownership:** 6-digit OTP entered in-app (no magic links / deep linking).
- **Enforcement:** block until verified — registration does **not** issue a usable session;
  login is refused for unverified accounts until the code is confirmed.
- **OTP policy:** 6 digits, 10-minute expiry, max 5 wrong attempts per code, 60-second resend
  cooldown.
- **Offline/mock mode:** applies the same stricter email-format validation and requires
  register-before-login, but **simulates instant verification** (there is no mail server in
  demo mode); the full OTP round-trip requires the backend.

## Non-goals

- Password reset / forgot-password, magic links, OAuth / social login.
- Changing the JWT scheme or password hashing.
- Rate limiting beyond the per-code attempt cap and resend cooldown.
- Internationalizing the email body (English only; ARB remains frozen — see
  [[i18n-translation-freeze]]).

---

## Component design

### 1. Backend — data model (`server/lib/src/database.dart`)

- `users` table: add column `email_verified BOOLEAN NOT NULL DEFAULT FALSE`. Idempotent
  migration: `ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE;`
  run on startup alongside the existing `CREATE TABLE IF NOT EXISTS` migrations.
- New table:
  ```sql
  CREATE TABLE IF NOT EXISTS email_verification_codes (
    uid TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL,
    code_salt TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_sent_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
  );
  ```
  One row per user (PK = uid); resend upserts (replaces code_hash/code_salt/expires_at/
  last_sent_at, resets attempts to 0). The OTP is stored **hashed**, never in plaintext:
  `code_salt = newSalt()` and `code_hash = hashPassword(code, code_salt)` (reusing the existing
  salted-sha256 helpers in `auth.dart`). A per-code salt defeats DB-leak brute force of the
  small 6-digit space.
- New DB methods: `setEmailVerified(uid)`, `upsertVerificationCode(uid, codeHash, codeSalt, expiresAt, sentAt)`,
  `verificationCodeFor(uid)` (returns hash+salt+expiry+attempts+lastSentAt),
  `incrementVerificationAttempts(uid)`, `deleteVerificationCode(uid)`.

### 2. Backend — email sender (`server/lib/src/email_sender.dart`, new)

- Abstract `EmailSender { Future<void> sendVerificationCode({required String to, required String code}); }`.
- `SmtpEmailSender` — sends via SMTP using the `mailer` package (added to `server/pubspec.yaml`).
  Reads `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM` from config.
- `ConsoleEmailSender` — logs `"[email] verification code for <to>: <code>"` to stdout. Used when
  SMTP config is absent.
- `config.dart`: load the SMTP env vars (all optional). `server.dart` selects
  `SmtpEmailSender` when `SMTP_HOST` is non-empty, else `ConsoleEmailSender`, and injects it
  into the router. Tests inject a `FakeEmailSender` that records the last `(to, code)`.

**Interface/contract:** the rest of the app depends only on `EmailSender`; swapping SMTP vs
console vs fake changes nothing else.

### 3. Backend — endpoints (`server/lib/src/routes.dart`)

Email-format validation helper `isValidEmail(String)` (regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`,
shared by the handlers).

- **`POST /auth/register`** (changed): require `name`, `isValidEmail(email)`, `password.length >= 6`
  (else `400`). Reject duplicate (`409`). Create user with `email_verified=false`. Generate a
  6-digit code, hash+store it (expiry now+10m), send via `EmailSender`. Respond
  `202 {"status":"verification_required","email":<email>}` — **no token**.
- **`POST /auth/verify`** `{email, code}`: look up user; if already verified return
  `200 {token,user}` (idempotent convenience). Load code row; if missing/expired → `410`; if
  `attempts >= 5` → `429`; if code mismatch → increment attempts, `400 {"error":"invalid_code"}`.
  On match: `setEmailVerified`, delete code row, issue JWT, return `200 {token, user}`.
- **`POST /auth/resend`** `{email}`: if user missing or already verified → `200` no-op (don't
  leak existence); if `now - last_sent_at < 60s` → `429 {"error":"resend_cooldown", retryAfter}`;
  else regenerate+send, `200 {"status":"sent"}`.
- **`POST /auth/login`** (changed): on valid credentials but `email_verified=false` → regenerate
  + send a fresh code and return `403 {"error":"email_not_verified","email":<email>}` (no token).
  Verified users get the token as before.
- `userDto` gains `"emailVerified": <bool>`.

### 4. Client (`linguaquest/lib/`)

- **Form validation** (`features/auth/login_screen.dart`, `register_screen.dart`): replace the
  `contains('@')` check with the shared regex `^[^@\s]+@[^@\s]+\.[^@\s]+$` via a small util
  `core/utils/email_validation.dart` (`isValidEmail(String)`), reused by the mock repo. Keep
  using the existing ARB error key `authEmailInvalid` (no new ARB keys).
- **Model** (`data/models/user_profile.dart`): add `bool emailVerified` (default `true` so
  existing/offline profiles are unaffected); thread through `fromJson`/`toJson`/`copyWith`.
- **`AuthRepository` interface**: `register(...)` returns a sealed result
  `AuthResult` = `AuthSuccess(UserProfile)` | `AuthVerificationRequired(String email)`; add
  `Future<UserProfile> verifyEmail({required String email, required String code})` and
  `Future<void> resendCode(String email)`. `login` throws a typed
  `EmailNotVerifiedException(email)` on `403 email_not_verified`.
- **`ApiAuthRepository`**: implement the above against the new endpoints; `verifyEmail` saves
  the returned token+profile (same path as today's `_saveAuthResponse`).
- **`MockAuthRepository`** (offline/demo): enforce `isValidEmail`; `register` stores the email
  and returns `AuthSuccess` with `emailVerified=true` (instant verify); `login` of an
  unregistered email **fails** (`StateError`) instead of fabricating a user. `verifyEmail`/
  `resendCode` are no-ops returning success.
- **New screen** `features/auth/verify_email_screen.dart`: 6-box code entry, "Resend"
  with a 60s countdown, inline error text for invalid/expired/too-many-attempts. On success →
  `AppController` stores session → routes to `/home` (or goal setup if profile incomplete).
- **Routing/flow** (`app_router.dart`, `AppController`): `register` → if
  `AuthVerificationRequired` push `/verify-email?email=`; `login` catching
  `EmailNotVerifiedException` → push `/verify-email?email=`. `AppController` gets
  `verifyEmail`/`resendCode` methods mirroring `login`.

### 5. Error handling

- Network/5xx → existing friendly-error path (`AppController._run`/`_friendlyError`).
- Specific OTP failures map to user-facing messages on the verify screen (reuse existing
  generic ARB strings where possible; otherwise plain English literals, ARB frozen):
  invalid code, expired (prompt resend), too many attempts (prompt resend), cooldown (disable
  resend with countdown).

### 6. Testing

- **Server** (`cd server && dart test`): a `FakeEmailSender` captures the code.
  - register → `202 verification_required`, no token, user row `email_verified=false`, code stored.
  - verify wrong code → `400`, attempts increments; 5th wrong → `429`.
  - verify expired code → `410`.
  - verify correct → `200` with token, `email_verified=true`, code row deleted.
  - login before verify → `403 email_not_verified` (and a new code sent); after verify → `200`.
  - resend within 60s → `429`; after → new code.
  - `isValidEmail` rejects `a@b`, `user@`, `x y@z.com`; accepts `a@b.co`.
- **Client** (`cd linguaquest && flutter test`):
  - `isValidEmail` unit test (shared util).
  - register/login form validators reject garbled emails.
  - `MockAuthRepository`: garbled email rejected; unregistered login fails; registered login
    succeeds with `emailVerified=true`.
  - verify-email screen: enter code → success routes home; resend countdown disables button.
- **Gates:** `dart test` (server), `flutter analyze` + `flutter test` (app) all green, output shown.

## Data flow (backend path)

1. Register → user row (`email_verified=false`) + code emailed (or console-logged) → app shows
   verify screen (`202`, no token).
2. User enters code → `POST /auth/verify` → server verifies → JWT issued → app stores session →
   home.
3. Later login on unverified account → `403` + fresh code → app routes to verify screen.

## Risks / edge cases

- **No SMTP configured in dev/CI:** `ConsoleEmailSender` logs the code; tests use
  `FakeEmailSender`. Real delivery only when `SMTP_HOST` is set. Documented in `server/README`.
- **Offline/demo has no mail server:** verification is simulated (instant) so the demo stays
  usable; the strict format check still fixes the "garbled email logs in" complaint.
- **Existing accounts** (created before this change) have `email_verified` defaulting to
  `FALSE` after migration — they would be forced to verify on next login. If undesirable for
  already-active accounts, the migration can backfill `email_verified=TRUE` for rows created
  before the migration timestamp. **Decision:** backfill existing rows to `TRUE` (only new
  registrations must verify), to avoid locking out current users.
- **Code brute force:** mitigated by hashed storage, 5-attempt cap, 10-min expiry, 60s resend
  cooldown.
- **`mailer` dependency:** new server dependency; pinned in `server/pubspec.yaml`.
