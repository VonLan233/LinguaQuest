import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/utils/spaced_repetition.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';

void main() {
  test('custom word learned correctly once is not weak (mistake book 6.2)', () {
    final now = DateTime(2026, 1, 1);
    final created = CustomWord.create(
      id: 'c1',
      uid: 'u1',
      word: '爱',
      meaning: '爱',
      exampleSentence: '',
      now: now,
      englishDefinitions: const ['to love'],
    );
    final learned = created.reviewed(isCorrect: true, now: now);
    expect(learned.masteryLevel, 1);
    expect(learned.wrongCount, 0);
    // masteryLevel 1 with no mistakes must NOT surface in the mistake book.
    expect(learned.isWeak, isFalse);

    final missed = created.reviewed(isCorrect: false, now: now);
    expect(missed.isWeak, isTrue);
  });

  test('review intervals follow the blueprint', () {
    expect(reviewIntervalForLevel(0), Duration.zero);
    expect(reviewIntervalForLevel(1), const Duration(days: 1));
    expect(reviewIntervalForLevel(2), const Duration(days: 3));
    expect(reviewIntervalForLevel(3), const Duration(days: 7));
    expect(reviewIntervalForLevel(4), const Duration(days: 14));
    expect(reviewIntervalForLevel(5), const Duration(days: 30));
  });

  test('custom word review updates mastery and counters', () {
    final now = DateTime(2026, 5, 25, 10);
    final word = CustomWord.create(
      id: '1',
      uid: 'u1',
      word: 'focus',
      meaning: '专注',
      exampleSentence: 'Focus on one lesson.',
      now: now,
    );

    final correct = word.reviewed(isCorrect: true, now: now);
    expect(correct.masteryLevel, 1);
    expect(correct.correctCount, 1);
    expect(correct.nextReviewAt, now.add(const Duration(days: 1)));

    final wrong = correct.reviewed(isCorrect: false, now: now);
    expect(wrong.masteryLevel, 0);
    expect(wrong.wrongCount, 1);
  });

  test('custom word review updates only the selected mastery dimension', () {
    final now = DateTime(2026, 5, 25, 10);
    final word = CustomWord.create(
      id: '2',
      uid: 'u1',
      word: 'spell',
      meaning: '拼写',
      exampleSentence: 'Spell the word carefully.',
      now: now,
    );

    final reviewed = word.reviewed(
      isCorrect: true,
      now: now,
      dimension: ReviewDimension.spelling,
    );

    expect(reviewed.spellingScore, word.spellingScore + 12);
    expect(reviewed.meaningRecognitionScore, word.meaningRecognitionScore);
    expect(reviewed.meaningRecallScore, word.meaningRecallScore);
    expect(reviewed.listeningScore, word.listeningScore);
    expect(reviewed.contextScore, word.contextScore);
    expect(reviewed.confidenceScore, word.confidenceScore);
  });

  test('custom word JSON accepts double-backed integer values', () {
    final word = CustomWord.fromJson({
      'id': '3',
      'uid': 'u1',
      'word': 'robust',
      'meaning': '健壮的',
      'masteryLevel': 2.0,
      'intervalDays': 3.0,
      'repetitionCount': 4.0,
      'lapseCount': 1.0,
      'correctCount': 5.0,
      'wrongCount': 2.0,
      'meaningRecognitionScore': 60.0,
      'spellingScore': 55.0,
    });

    expect(word.status, 'Review');
    expect(word.masteryLevel, 2);
    expect(word.intervalDays, 3);
    expect(word.repetitionCount, 4);
    expect(word.lapseCount, 1);
    expect(word.correctCount, 5);
    expect(word.wrongCount, 2);
    expect(word.meaningRecognitionScore, 60);
    expect(word.spellingScore, 55);
    expect(word.meaningRecallScore, 40);
  });

  test('user word JSON preserves status flags and mastery dimensions', () {
    final now = DateTime(2026, 5, 25, 10);
    final word = UserWord.fromJson({
      'id': 'uw-1',
      'uid': 'u1',
      'wordId': 'target-1',
      'wordBookId': 'IELTS',
      'word': 'abstract',
      'meaning': '抽象的',
      'status': 'Previewed',
      'isFavorite': true,
      'isInNew'
              'Word'
              'Book':
          true,
      'isIgnored': false,
      'easeFactor': 2.6,
      'intervalDays': 3,
      'repetitionCount': 2,
      'lapseCount': 1,
      'masteryLevel': 2,
      'correctCount': 4,
      'wrongCount': 1,
      'meaningRecognitionScore': 70,
      'meaningRecallScore': 60,
      'spellingScore': 50,
      'listeningScore': 40,
      'contextScore': 55,
      'confidenceScore': 65,
      'nextReviewAt': now.toIso8601String(),
      'lastReviewedAt': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    final json = word.toJson();
    expect(json['status'], 'Previewed');
    expect(json['isFavorite'], true);
    expect(
      json['isInNew'
          'Word'
          'Book'],
      true,
    );
    expect(json['spellingScore'], 50);
    expect(json['lastReviewedAt'], now.toIso8601String());
  });

  test('user word learning creates review or relearning schedule', () {
    final now = DateTime(2026, 5, 25, 10);
    final target = Word(
      id: 'w1',
      word: 'context',
      phonetic: '/ˈkɒntekst/',
      meaning: '语境',
      definition: 'The situation in which something happens.',
      partOfSpeech: 'noun',
      exampleSentence: 'Use the word in context.',
      exampleTranslation: '在语境中使用这个词。',
      imageCue: '📚',
      difficulty: 'Medium',
      tags: const ['academic'],
    );
    final created = UserWord.create(
      uid: 'u1',
      word: target,
      wordBookId: 'IELTS',
      now: now,
    );

    final learned = created.learned(hadMistake: false, now: now);
    expect(learned.status, 'Review');
    expect(learned.correctCount, 1);
    expect(learned.nextReviewAt, now.add(const Duration(days: 1)));
    // A word answered correctly (masteryLevel 0->1, no mistakes) must NOT be
    // "weak", otherwise the mistake book lists every studied word (bug 6.2).
    expect(learned.masteryLevel, 1);
    expect(learned.isWeak, isFalse);

    final relearning = created.learned(hadMistake: true, now: now);
    expect(relearning.status, 'Relearning');
    expect(relearning.wrongCount, 1);
    expect(relearning.nextReviewAt.day, now.day);
    // A word answered wrong is genuinely weak and belongs in the mistake book.
    expect(relearning.isWeak, isTrue);
  });

  test('review words deduplicate custom copies and prefer target progress', () {
    final now = DateTime(2026, 5, 25, 10);
    final target = Word(
      id: 'w-dedupe',
      word: 'Allocate',
      phonetic: '/ˈæləkeɪt/',
      meaning: '分配',
      definition: 'To distribute resources for a purpose.',
      partOfSpeech: 'verb',
      exampleSentence: 'Allocate time for review.',
      exampleTranslation: '分配时间复习。',
      imageCue: '🧭',
      difficulty: 'Medium',
      tags: const ['academic'],
    );
    final userWord = UserWord.create(
      uid: 'u1',
      word: target,
      wordBookId: 'IELTS',
      now: now,
    ).reviewed(isCorrect: true, now: now);
    final customCopy = CustomWord.create(
      id: 'custom-allocate',
      uid: 'u1',
      word: ' allocate ',
      meaning: '分配',
      exampleSentence: 'Allocate time for review.',
      now: now,
    );

    final state = AppState.initial().copyWith(
      customWords: [customCopy],
      userWords: [userWord],
    );

    expect(state.reviewWords, hasLength(1));
    expect(state.reviewWords.single.source, 'target');
    expect(state.reviewWords.single.masteryLevel, userWord.masteryLevel);
    expect(identical(state.reviewWords, state.reviewWords), true);
  });

  test('review words exclude new previewed and ignored cards', () {
    final now = DateTime(2026, 5, 25, 10);
    final target = Word(
      id: 'w-filter',
      word: 'Filter',
      phonetic: '/ˈfɪltər/',
      meaning: '过滤',
      definition: 'To remove unwanted items.',
      partOfSpeech: 'verb',
      exampleSentence: 'Filter words before review.',
      exampleTranslation: '复习前过滤单词。',
      imageCue: '🧹',
      difficulty: 'Medium',
      tags: const ['review'],
    );
    final baseUserWord = UserWord.create(
      uid: 'u1',
      word: target,
      wordBookId: 'IELTS',
      now: now,
    );
    final eligibleUserWord = baseUserWord.copyWith(
      wordId: 'w-review',
      word: 'reviewable',
      status: 'Review',
    );
    final ignoredUserWord = baseUserWord.copyWith(
      wordId: 'w-ignored',
      word: 'ignored-target',
      status: 'Review',
      isIgnored: true,
    );
    final previewedUserWord = baseUserWord.copyWith(
      wordId: 'w-previewed',
      word: 'previewed-target',
      status: 'Previewed',
    );
    final newUserWord = baseUserWord.copyWith(
      wordId: 'w-new',
      word: 'new-target',
    );
    final eligibleCustomWord = CustomWord.create(
      id: 'custom-review',
      uid: 'u1',
      word: 'custom-review',
      meaning: '复习',
      exampleSentence: 'Review this word.',
      now: now,
    );
    final ignoredCustomWord = CustomWord.create(
      id: 'custom-ignored',
      uid: 'u1',
      word: 'custom-ignored',
      meaning: '忽略',
      exampleSentence: 'Ignore this word.',
      now: now,
    ).copyWith(isIgnored: true);
    final newCustomWord = eligibleCustomWord.copyWith(
      id: 'custom-new',
      word: 'custom-new',
      status: 'New',
    );

    final state = AppState.initial().copyWith(
      customWords: [eligibleCustomWord, ignoredCustomWord, newCustomWord],
      userWords: [
        eligibleUserWord,
        ignoredUserWord,
        previewedUserWord,
        newUserWord,
      ],
    );

    expect(state.reviewWords.map((word) => word.word), [
      'reviewable',
      'custom-review',
    ]);
  });

  test('learning user word due state matches its review card', () {
    final now = DateTime(2026, 5, 25, 10);
    final target = Word(
      id: 'w-learning-due',
      word: 'consistent',
      phonetic: '/kənˈsɪstənt/',
      meaning: '一致的',
      definition: 'Always behaving in the same way.',
      partOfSpeech: 'adjective',
      exampleSentence: 'Keep review behavior consistent.',
      exampleTranslation: '保持复习行为一致。',
      imageCue: '🔁',
      difficulty: 'Medium',
      tags: const ['review'],
    );
    final word = UserWord.create(
      uid: 'u1',
      word: target,
      wordBookId: 'IELTS',
      now: now.subtract(const Duration(days: 1)),
    ).copyWith(status: 'Learning', nextReviewAt: now);

    expect(word.isDue(now), true);
    expect(word.toReviewCard().isDue(now), true);
  });

  test('ignored user words are excluded from due review cards', () {
    final now = DateTime(2026, 5, 25, 10);
    final target = Word(
      id: 'w2',
      word: 'simple',
      phonetic: '/ˈsɪmpəl/',
      meaning: '简单的',
      definition: 'Easy to understand.',
      partOfSpeech: 'adjective',
      exampleSentence: 'This is a simple word.',
      exampleTranslation: '这是一个简单词。',
      imageCue: '✅',
      difficulty: 'Easy',
      tags: const ['daily'],
    );
    final ignored = UserWord.create(
      uid: 'u1',
      word: target,
      wordBookId: 'Daily',
      now: now,
    ).copyWith(status: 'Ignored', isIgnored: true);

    expect(ignored.isDue(now), false);
    expect(ignored.toReviewCard().isDue(now), false);
  });
}
