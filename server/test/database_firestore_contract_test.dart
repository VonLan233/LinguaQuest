import 'package:linguaquest_server/src/database.dart';
import 'package:test/test.dart';

void main() {
  test('user registration creates a user and email index', () async {
    final database = InMemoryAppDatabase();

    await database.insertUser(
      id: 'user-1',
      email: 'Learner@Lingua.Quest',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      name: 'Learner',
    );

    final byId = await database.userById('user-1');
    final byEmail = await database.userByEmail('learner@lingua.quest');
    expect(byId?['email'], 'learner@lingua.quest');
    expect(byEmail?['id'], 'user-1');
    expect(byEmail?['password_hash'], 'hash');
    expect(byEmail?['password_salt'], 'salt');
  });

  test('duplicate emails are rejected', () async {
    final database = InMemoryAppDatabase();
    await database.insertUser(
      id: 'user-1',
      email: 'learner@lingua.quest',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      name: 'Learner',
    );

    expect(
      () => database.insertUser(
        id: 'user-2',
        email: 'LEARNER@lingua.quest',
        passwordHash: 'hash',
        passwordSalt: 'salt',
        name: 'Duplicate',
      ),
      throwsStateError,
    );
  });

  test('custom word CRUD preserves review fields', () async {
    final database = InMemoryAppDatabase();
    final dueAt = DateTime.utc(2026, 6, 1, 8);

    final created = await database.upsertCustomWord('user-1', {
      'id': 'word-1',
      'word': 'abstract',
      'meaning': '抽象的',
      'exampleSentence': 'The idea is abstract.',
      'status': 'Review',
      'easeFactor': 2.7,
      'intervalDays': 7,
      'repetitionCount': 3,
      'lapseCount': 1,
      'masteryLevel': 4,
      'correctCount': 8,
      'wrongCount': 2,
      'meaningRecognitionScore': 80,
      'meaningRecallScore': 70,
      'spellingScore': 60,
      'listeningScore': 50,
      'contextScore': 75,
      'confidenceScore': 65,
      'nextReviewAt': dueAt,
    });

    expect(created['ease_factor'], 2.7);
    expect(created['meaning_recognition_score'], 80);
    expect((await database.customWords('user-1')).single['id'], 'word-1');

    final updated = await database.upsertCustomWord('user-1', {
      ...created,
      'word': 'abstracted',
      'meaning': '提取',
    }, id: 'word-1');
    expect(updated['word'], 'abstracted');
    expect(updated['mastery_level'], 4);

    await database.deleteCustomWord('user-1', 'word-1');
    expect(await database.customWords('user-1'), isEmpty);
  });

  test('due review filtering includes only due review items', () async {
    final database = InMemoryAppDatabase();
    final past = DateTime.now().toUtc().subtract(const Duration(days: 1));
    final future = DateTime.now().toUtc().add(const Duration(days: 1));

    await database.upsertCustomWord('user-1', {
      'id': 'due-custom',
      'word': 'due',
      'meaning': '到期',
      'nextReviewAt': past,
    });
    await database.upsertCustomWord('user-1', {
      'id': 'future-custom',
      'word': 'future',
      'meaning': '未来',
      'nextReviewAt': future,
    });
    await database.upsertUserWord('user-1', {
      'id': 'target-due',
      'wordId': 'w-1',
      'word': 'target',
      'status': 'Review',
      'nextReviewAt': past,
    });
    await database.upsertUserWord('user-1', {
      'id': 'target-new',
      'wordId': 'w-2',
      'word': 'new',
      'status': 'New',
      'nextReviewAt': past,
    });

    expect(
      (await database.customWords(
        'user-1',
        dueOnly: true,
      )).map((row) => row['id']),
      contains('due-custom'),
    );
    expect(
      (await database.userWords(
        'user-1',
        dueOnly: true,
      )).map((row) => row['id']),
      ['target-due'],
    );
    expect(await database.dueReviewCount('user-1'), 2);
  });

  test('study sessions and review events are recorded per user', () async {
    final database = InMemoryAppDatabase();
    final startedAt = DateTime.utc(2026, 6, 6, 8);
    final endedAt = DateTime.utc(2026, 6, 6, 8, 5);
    await database.insertStudySession('user-1', {
      'id': 'session-1',
      'lessonId': 'lesson-1',
      'startedAt': startedAt,
      'endedAt': endedAt,
      'totalQuestions': 10,
      'correctAnswers': 8,
      'xpEarned': 40,
      'mistakeWordIds': ['w-1'],
    });
    await database.insertReviewEvent('user-1', {
      'id': 'review-1',
      'wordId': 'w-1',
      'isCorrect': true,
      'reviewedAt': endedAt,
      'nextReviewAt': endedAt.add(const Duration(days: 1)),
    });

    expect(await database.completedLessonIds('user-1'), ['lesson-1']);
    expect(
      await database.lessonIdsInRange(
        'user-1',
        startedAt.subtract(const Duration(minutes: 1)),
        endedAt.add(const Duration(minutes: 1)),
      ),
      ['lesson-1'],
    );
    expect(
      await database.reviewWordIdsInRange(
        'user-1',
        startedAt,
        endedAt.add(const Duration(minutes: 1)),
      ),
      ['w-1'],
    );
  });
}
