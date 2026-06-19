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
