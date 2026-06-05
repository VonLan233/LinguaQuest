import 'package:linguaquest_server/src/routes.dart';
import 'package:test/test.dart';

void main() {
  test('bodyString safely normalizes missing and non-string fields', () {
    expect(bodyString({}, 'wordId'), '');
    expect(bodyString({'wordId': null}, 'wordId'), '');
    expect(bodyString({'wordId': 42}, 'wordId'), '42');
    expect(bodyString({'wordId': ' target-1 '}, 'wordId'), 'target-1');
  });

  test('userWordBatchItems filters entries without valid wordId', () {
    final words = userWordBatchItems([
      {'id': ' user-word-1 ', 'wordId': ' target-1 ', 'status': 'Review'},
      {'id': 'missing-word-id', 'wordId': ''},
      {'wordId': 'missing-id'},
      null,
      'not a map',
      {'id': 42, 'wordId': 84, 'status': 'Learning'},
    ]);

    expect(words, hasLength(2));
    expect(words.map((word) => bodyString(word, 'id')), ['user-word-1', '42']);
    expect(words.map((word) => bodyString(word, 'wordId')), ['target-1', '84']);
  });
}
