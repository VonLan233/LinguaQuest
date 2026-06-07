import 'package:linguaquest_server/src/database.dart';
import 'package:test/test.dart';

void main() {
  test('resetCustomWordProgress persists a bulk custom word reset', () async {
    final database = InMemoryAppDatabase();
    final originalReviewAt = DateTime.utc(2026, 6, 1, 8);
    final resetAt = DateTime.utc(2026, 6, 4, 9, 30);
    await database.insertUser(
      id: 'reset-user',
      email: 'reset@lingua.quest',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      name: 'Reset User',
    );
    await database.insertUser(
      id: 'other-user',
      email: 'other@lingua.quest',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      name: 'Other User',
    );
    await database.upsertCustomWord('reset-user', {
      'id': 'word-1',
      'word': 'abstract',
      'meaning': '抽象的',
      'masteryLevel': 4,
      'correctCount': 7,
      'wrongCount': 2,
      'nextReviewAt': originalReviewAt,
    });
    await database.upsertCustomWord('other-user', {
      'id': 'word-2',
      'word': 'effect',
      'meaning': '影响',
      'masteryLevel': 5,
      'correctCount': 9,
      'wrongCount': 0,
      'nextReviewAt': originalReviewAt,
    });

    await database.resetCustomWordProgress('reset-user', now: resetAt);

    final resetWord = await database.customWordById('reset-user', 'word-1');
    final otherWord = await database.customWordById('other-user', 'word-2');
    expect(resetWord?['mastery_level'], 0);
    expect(resetWord?['correct_count'], 0);
    expect(resetWord?['wrong_count'], 0);
    expect(resetWord?['next_review_at'], resetAt);
    expect(resetWord?['updated_at'], resetAt);
    expect(otherWord?['mastery_level'], 5);
    expect(otherWord?['next_review_at'], originalReviewAt);
  });
}
