import 'package:test/test.dart';

import '../lib/src/recommendation_policy.dart';

void main() {
  group('RecommendationPolicy', () {
    test('returns empty list when wordStats is empty', () {
      final recs = RecommendationPolicy.generate(wordStats: []);
      expect(recs, isEmpty);
    });

    test('returns empty list when no word has a weak score', () {
      final wordStats = [
        {'wordId': 'w1', 'listeningScore': 80, 'contextScore': 90, 'meaningRecallScore': 75},
        {'wordId': 'w2', 'listeningScore': 65, 'contextScore': 50, 'meaningRecallScore': 60},
      ];
      final recs = RecommendationPolicy.generate(wordStats: wordStats);
      expect(recs, isEmpty);
    });

    test('returns listening recommendation when listeningScore < 30', () {
      final wordStats = [
        {'wordId': 'w1', 'listeningScore': 20, 'contextScore': 80, 'meaningRecallScore': 70},
      ];
      final recs = RecommendationPolicy.generate(wordStats: wordStats);
      expect(recs, hasLength(1));
      expect(recs.first.exerciseType, equals('listeningWordChoice'));
      expect(recs.first.priority, equals(1));
      expect(recs.first.targetWordIds, contains('w1'));
    });

    test('returns context recommendation when contextScore < 30', () {
      final wordStats = [
        {'wordId': 'w2', 'listeningScore': 80, 'contextScore': 15, 'meaningRecallScore': 70},
      ];
      final recs = RecommendationPolicy.generate(wordStats: wordStats);
      expect(recs, hasLength(1));
      expect(recs.first.exerciseType, equals('sentenceCloze'));
      expect(recs.first.priority, equals(2));
      expect(recs.first.targetWordIds, contains('w2'));
    });

    test('returns meaning recall recommendation when meaningRecallScore < 30', () {
      final wordStats = [
        {'wordId': 'w3', 'listeningScore': 80, 'contextScore': 70, 'meaningRecallScore': 10},
      ];
      final recs = RecommendationPolicy.generate(wordStats: wordStats);
      expect(recs, hasLength(1));
      expect(recs.first.exerciseType, equals('meaningChoice'));
      expect(recs.first.priority, equals(3));
    });

    test('caps at 5 words per recommendation', () {
      final wordStats = List.generate(
        10,
        (i) => {
          'wordId': 'w$i',
          'listeningScore': 10,
          'contextScore': 80,
          'meaningRecallScore': 70,
        },
      );
      final recs = RecommendationPolicy.generate(wordStats: wordStats);
      final listeningRec = recs.firstWhere((r) => r.exerciseType == 'listeningWordChoice');
      expect(listeningRec.targetWordIds, hasLength(5));
    });

    test('priority 1 is listening, priority 2 is context, priority 3 is meaning', () {
      final wordStats = [
        {'wordId': 'w1', 'listeningScore': 10, 'contextScore': 10, 'meaningRecallScore': 10},
      ];
      final recs = RecommendationPolicy.generate(wordStats: wordStats);
      final priorities = recs.map((r) => r.priority).toList();
      expect(priorities, containsAll([1, 2, 3]));
      expect(priorities[0], equals(1)); // listening first
      expect(priorities[1], equals(2)); // context second
      expect(priorities[2], equals(3)); // meaning third
    });

    test('Recommendation toJson/fromJson round-trip', () {
      const rec = Recommendation(
        targetWordIds: ['w1', 'w2'],
        exerciseType: 'listeningWordChoice',
        reason: 'test reason',
        priority: 1,
        estimatedMinutes: 3,
      );
      final json = rec.toJson();
      final restored = Recommendation.fromJson(json);
      expect(restored.targetWordIds, equals(rec.targetWordIds));
      expect(restored.exerciseType, equals(rec.exerciseType));
      expect(restored.reason, equals(rec.reason));
      expect(restored.priority, equals(rec.priority));
      expect(restored.estimatedMinutes, equals(rec.estimatedMinutes));
    });
  });
}
