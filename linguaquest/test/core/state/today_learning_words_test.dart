import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'todayLearningWords reflects the new words a mixed session actually '
    'studied, not the fixed 3-word lesson chunk (bug 6.1)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(appControllerProvider.notifier);

      // bootstrap loads the bundled wordbooks/lessons; enterDemo attaches the
      // demo user + study plan (dailyNewTarget defaults to 10).
      await controller.bootstrap();
      await controller.enterDemo();

      final state = container.read(appControllerProvider);
      final book = state.currentWordBook;
      expect(book, isNotNull);

      // Ten distinct new words — more than the 3-word current lesson chunk the
      // old counter was pinned to.
      final newWordIds = book!.words.take(10).map((word) => word.id).toList();
      expect(newWordIds.length, 10);

      final now = DateTime.now();
      await controller.completeMixedStudySession(
        lessonId: 'daily-mixed-session',
        totalQuestions: newWordIds.length,
        correctAnswers: newWordIds.length,
        mistakeWordIds: const [],
        answerEvents: [
          for (final id in newWordIds) {'source': 'newWord', 'wordId': id},
        ],
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
      );

      // The home "today's learning" counter must equal the 10 new words the
      // session studied, so a 10/day goal can actually be satisfied.
      expect(container.read(appControllerProvider).todayLearningWords, 10);
    },
  );
}
