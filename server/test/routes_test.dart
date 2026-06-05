import 'package:linguaquest_server/src/routes.dart';
import 'package:test/test.dart';

void main() {
  test('bodyString safely normalizes missing and non-string fields', () {
    expect(bodyString({}, 'wordId'), '');
    expect(bodyString({'wordId': null}, 'wordId'), '');
    expect(bodyString({'wordId': 42}, 'wordId'), '42');
    expect(bodyString({'wordId': ' target-1 '}, 'wordId'), 'target-1');
  });
}
