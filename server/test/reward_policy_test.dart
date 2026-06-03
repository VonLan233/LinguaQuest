import 'package:linguaquest_server/src/reward_policy.dart';
import 'package:test/test.dart';

void main() {
  group('validatedRewardPoints', () {
    final nowUtc = DateTime.utc(2026, 6, 3, 12);

    test('allows current client reward source id shapes', () {
      final lesson = validatedRewardPoints(
        sourceType: 'study_lesson',
        sourceId: 'lesson-campus-1',
        requestedPoints: 20,
        nowUtc: nowUtc,
      );
      expect(lesson?.points, 20);
      expect(lesson?.canonicalSourceId, 'lesson-campus-1');

      final training = validatedRewardPoints(
        sourceType: 'training_session',
        sourceId: 'lesson-campus-1:2026-06-03',
        requestedPoints: 20,
        nowUtc: nowUtc,
      );
      expect(training?.points, 20);
      expect(training?.canonicalSourceId, 'lesson-campus-1:2026-06-03');

      final review = validatedRewardPoints(
        sourceType: 'review_word',
        sourceId: 'custom-1:2026-06-03',
        requestedPoints: 3,
        nowUtc: nowUtc,
      );
      expect(review?.points, 3);
      expect(review?.canonicalSourceId, 'custom-1:2026-06-03');

      final reward = validatedRewardPoints(
        sourceType: 'reward_task',
        sourceId: 'daily-checkin:2026-06-03',
        requestedPoints: 5,
        nowUtc: nowUtc,
      );
      expect(reward?.points, 5);
      expect(reward?.canonicalSourceId, 'daily-checkin:2026-06-03');
    });

    test('canonicalizes adjacent local dates to one server reward day', () {
      final canonicalIds = [
        for (final dateKey in ['2026-06-02', '2026-06-03', '2026-06-04'])
          validatedRewardPoints(
            sourceType: 'reward_task',
            sourceId: 'daily-checkin:$dateKey',
            requestedPoints: 5,
            nowUtc: nowUtc,
          )?.canonicalSourceId,
      ];

      expect(canonicalIds.toSet(), {'daily-checkin:2026-06-03'});
    });

    test('rejects arbitrary dates outside the server reward window', () {
      for (final dateKey in ['2026-06-01', '2026-06-05', '2099-01-01']) {
        expect(
          validatedRewardPoints(
            sourceType: 'reward_task',
            sourceId: 'daily-checkin:$dateKey',
            requestedPoints: 5,
            nowUtc: nowUtc,
          ),
          isNull,
        );
      }
    });

    test(
      'rejects arbitrary reward task suffixes that bypass daily uniqueness',
      () {
        expect(
          validatedRewardPoints(
            sourceType: 'reward_task',
            sourceId: 'daily-checkin:random1',
            requestedPoints: 5,
            nowUtc: nowUtc,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: 'reward_task',
            sourceId: 'daily-checkin:2026-06-03:extra',
            requestedPoints: 5,
            nowUtc: nowUtc,
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
            nowUtc: nowUtc,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1:2026-6-3',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
            nowUtc: nowUtc,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1:2026-06-03T00:00:00Z',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
            nowUtc: nowUtc,
          ),
          isNull,
        );
        expect(
          validatedRewardPoints(
            sourceType: sourceType,
            sourceId: 'source-1:2026-02-30',
            requestedPoints: sourceType == 'review_word' ? 3 : 20,
            nowUtc: nowUtc,
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
          nowUtc: nowUtc,
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
          nowUtc: nowUtc,
        ),
        isNull,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'reward_task',
          sourceId: 'unknown-task:2026-06-03',
          requestedPoints: 5,
          nowUtc: nowUtc,
        ),
        isNull,
      );
      expect(
        validatedRewardPoints(
          sourceType: 'review_word',
          sourceId: 'custom-1:2026-06-03',
          requestedPoints: 4,
          nowUtc: nowUtc,
        ),
        isNull,
      );
    });
  });
}
