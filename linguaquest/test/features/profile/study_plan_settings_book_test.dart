import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/study_plan.dart';
import 'package:linguaquest/features/profile/study_plan_settings_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

WordBook _book(String id, String title, String language) => WordBook(
  id: id,
  title: title,
  category: 'hsk',
  examType: title,
  coverUrl: '',
  totalWords: 100,
  includedWords: 100,
  description: 'desc-$id',
  wordIds: const [],
  createdAt: DateTime(2026, 1, 1),
  words: const [],
  language: language,
);

void main() {
  testWidgets('study plan hero shows the selected wordbook (HSK 2), not HSK 1', (
    tester,
  ) async {
    final user = UserProfile(
      uid: 'u1',
      name: 'V',
      email: 'v@example.com',
      level: 'Beginner',
      targetExam: 'HSK 2',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final plan = StudyPlan.fromJson({
      'uid': 'u1',
      'wordBookId': 'hsk2',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-06-20',
      'targetFinishDate': '2026-07-20',
      'reminderTime': '20:00',
      'status': 'active',
    });
    final state = AppState.initial().copyWith(
      isBootstrapped: true,
      user: user,
      wordBooks: [_book('hsk1', 'HSK 1', 'zh'), _book('hsk2', 'HSK 2', 'zh')],
      currentWordBookId: 'hsk2',
      studyPlan: plan,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(() => _FakeAppController(state)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const StudyPlanSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('HSK 2'), findsWidgets);
  });

  test('_wordBookForId matches by raw id', () {
    final books = [_book('hsk1', 'HSK 1', 'zh'), _book('hsk2', 'HSK 2', 'zh')];
    expect(wordBookForIdForTest(books, 'hsk2')?.id, 'hsk2');
    expect(wordBookForIdForTest(books, 'missing'), isNull);
  });

  testWidgets(
    'study plan settings shows no completion-date / days-left and no review-limit field',
    (tester) async {
      final user = UserProfile(
        uid: 'u1',
        name: 'V',
        email: 'v@example.com',
        level: 'Beginner',
        targetExam: 'HSK 2',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final plan = StudyPlan.fromJson({
        'uid': 'u1',
        'wordBookId': 'hsk2',
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-20',
        'targetFinishDate': '2026-07-20',
        'reminderTime': '20:00',
        'status': 'active',
      });
      final state = AppState.initial().copyWith(
        isBootstrapped: true,
        user: user,
        wordBooks: [_book('hsk1', 'HSK 1', 'zh'), _book('hsk2', 'HSK 2', 'zh')],
        currentWordBookId: 'hsk2',
        studyPlan: plan,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith(() => _FakeAppController(state)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const StudyPlanSettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('days left'), findsNothing);
      expect(find.text('Daily Review Limit'), findsNothing);
    },
  );
}
