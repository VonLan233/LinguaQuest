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
