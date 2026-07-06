import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── register ────────────────────────────────────────────────────────────────

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

  test('register rejects duplicate email', () async {
    final repo = MockAuthRepository();
    await repo.register(
        name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    expect(
      () => repo.register(
          name: 'B', email: 'ada@lingua.quest', password: 'secret2'),
      throwsA(isA<StateError>()),
    );
  });

  // ── login ───────────────────────────────────────────────────────────────────

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
    final profile =
        await repo.login(email: 'ada@lingua.quest', password: 'secret1');
    expect(profile.email, 'ada@lingua.quest');
  });

  // ── verifyEmail ─────────────────────────────────────────────────────────────

  test('verifyEmail accepts any 6-digit code after register (demo mode)',
      () async {
    final repo = MockAuthRepository();
    await repo.register(
        name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    final profile = await repo.verifyEmail(
      email: 'ada@lingua.quest',
      code: '123456',
    );
    expect(profile.email, 'ada@lingua.quest');
  });

  test('verifyEmail accepts 000000 (any all-digit 6-char code works)', () async {
    final repo = MockAuthRepository();
    await repo.register(
        name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    final profile = await repo.verifyEmail(
      email: 'ada@lingua.quest',
      code: '000000',
    );
    expect(profile.email, 'ada@lingua.quest');
  });

  test('verifyEmail throws EmailVerificationException for non-numeric code',
      () async {
    final repo = MockAuthRepository();
    await repo.register(
        name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    expect(
      () => repo.verifyEmail(email: 'ada@lingua.quest', code: 'ABCDEF'),
      throwsA(isA<EmailVerificationException>()),
    );
  });

  test('verifyEmail throws EmailVerificationException for short code',
      () async {
    final repo = MockAuthRepository();
    await repo.register(
        name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    expect(
      () => repo.verifyEmail(email: 'ada@lingua.quest', code: '123'),
      throwsA(isA<EmailVerificationException>()),
    );
  });

  test('verifyEmail returns existing session if already logged in', () async {
    final repo = MockAuthRepository();
    final result = await repo.register(
        name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    final sessionProfile = (result as AuthSuccess).profile;
    // Session already persisted by register — verifyEmail should return it.
    final profile = await repo.verifyEmail(
      email: 'ada@lingua.quest',
      code: '654321',
    );
    expect(profile.uid, sessionProfile.uid);
  });

  // ── resendCode ───────────────────────────────────────────────────────────────

  test('resendCode is a no-op in demo mode (does not throw)', () async {
    final repo = MockAuthRepository();
    await expectLater(
      repo.resendCode('ada@lingua.quest'),
      completes,
    );
  });
}
