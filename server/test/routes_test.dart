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

  test('nullableDateValue preserves null and formats DateTime as ISO8601', () {
    final timestamp = DateTime.utc(2026, 5, 25, 10, 30);

    expect(nullableDateValue(null), null);
    expect(nullableDateValue(timestamp), timestamp.toIso8601String());
    expect(
      nullableDateValue('2026-05-25T10:30:00.000Z'),
      '2026-05-25T10:30:00.000Z',
    );
  });

  test('word DTOs serialize nullable lastReviewedAt consistently', () {
    final timestamp = DateTime.utc(2026, 5, 25, 10, 30);

    expect(
      wordDto({'last_reviewed_at': timestamp})['lastReviewedAt'],
      timestamp.toIso8601String(),
    );
    expect(
      wordDto({'lastReviewedAt': 'saved-value'})['lastReviewedAt'],
      'saved-value',
    );
    expect(wordDto({})['lastReviewedAt'], null);
    expect(
      userWordDto({'last_reviewed_at': timestamp})['lastReviewedAt'],
      timestamp.toIso8601String(),
    );
    expect(
      userWordDto({'lastReviewedAt': 'saved-value'})['lastReviewedAt'],
      'saved-value',
    );
    expect(userWordDto({})['lastReviewedAt'], null);
  });

  test('notification DTO decodes params safely', () {
    final timestamp = DateTime.utc(2026, 6, 18, 9);

    expect(
      notificationDto({
        'id': 'n1',
        'uid': 'u1',
        'type': 'reviewDue',
        'title': '3 个词到期复习',
        'body': '先清理复习队列',
        'target_route': '/study/review',
        'is_read': false,
        'source_key': 'reviewDue:2026-06-18',
        'created_at': timestamp,
        'params': '{"dueCount":3}',
      })['params'],
      {'dueCount': 3},
    );

    expect(
      notificationDto({
        'id': 'n2',
        'uid': 'u1',
        'type': 'activity',
        'title': '活动',
        'body': '任务刷新',
        'created_at': timestamp,
        'params': '{bad json',
      })['params'],
      <String, dynamic>{},
    );
  });
}
