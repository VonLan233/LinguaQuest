import 'package:linguaquest_server/src/reward_policy.dart';
import 'package:test/test.dart';

void main() {
  group('validatedRewardPoints', () {
    test('allows current client reward source id shapes', () {
      expect(
        validatedRewardPoints(
          sourceType: 'study_lesson',
          sourceId: 'lesson-campus-1',
          requestedPoints: 20,
        ),
        20,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'training_session',
          sourceId: 'lesson-campus-1:2026-06-03',
          requestedPoints: 20,
        ),
        20,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'review_word',
          sourceId: 'custom-1:2026-06-03',
          requestedPoints: 3,
        ),
        3,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'reward_task',
          sourceId: 'daily-checkin:2026-06-03',
          requestedPoints: 5,
        ),
        5,
      );
    });

    test(
      'rejects arbitrary reward task suffixes that bypass daily uniqueness',
      () {
        expect(
          validatedRewardPoints(
            sourceType: 'reward_task',
            sourceId: 'daily-checkin:random1',
            requestedPoints: 5,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: 'reward_task',
            sourceId: 'daily-checkin:2026-06-03:extra',
            requestedPoints: 5,
          ),
          isNull,
        );
      },
    );

    test('requires strict date suffixes for repeatable reward sources', () {
      for (final sourceType in ['training_session', 'review_word']) {
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1:2026-6-3',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1:2026-06-03T00:00:00Z',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1:2026-02-30',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
          ),
          isNull,
        );
      }
    });

    test('keeps study lesson rewards single-use by rejecting suffixes', () {
      expect(
        validatedRewardPoints(
          sourceType: 'study_lesson',
          sourceId: 'lesson-campus-1:2026-06-03',
          requestedPoints: 20,
        ),
        isNull,
      );
    });

    test('rejects wrong point amounts and unknown reward tasks', () {
      expect(
        validatedRewardPoints(
          sourceType: 'reward_task',
          sourceId: 'daily-checkin:2026-06-03',
          requestedPoints: 6,
        ),
        isNull,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'reward_task',
          sourceId: 'unknown-task:2026-06-03',
          requestedPoints: 5,
        ),
        isNull,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'review_word',
          sourceId: 'custom-1:2026-06-03',
          requestedPoints: 4,
        ),
        isNull,
      );
    });
  });
}
