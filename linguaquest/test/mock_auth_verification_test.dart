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
    await repo.register(name: 'A', email: 'ada@lingua.quest', password: 'secret1');
    final profile =
        await repo.login(email: 'ada@lingua.quest', password: 'secret1');
    expect(profile.email, 'ada@lingua.quest');
  });
}
