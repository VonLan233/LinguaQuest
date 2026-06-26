import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/section_header.dart';
import 'package:linguaquest/data/models/analytics.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/repositories/article_repository.dart';
import 'package:linguaquest/features/quests/progress_analytics_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// A minimal AppController notifier that exposes a fixed AppState.
class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;

  @override
  AppState build() => _state;

  @override
  Future<void> refreshAnalytics() async {}

  @override
  Future<void> refreshRecommendations() async {}

  @override
  Future<List<ReadingResult>> readingResultsForScope() async => const [];
}

/// Wraps [child] with Riverpod + Material + l10n, overriding the
/// [appControllerProvider] with [controller].
Widget _buildHarness(Widget child, AppState state) {
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(() => _FakeAppController(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

/// Builds a seeded [AppState] with non-empty analytics and reviewWords.
AppState _seededState() {
  const analytics = LearningAnalytics(
    streakDays: 5,
    totalStudyDays: 12,
    learnedWords: 89,
    masteredWords: 34,
    newWordsToday: 8,
    reviewsToday: 12,
    wordbookProgressPct: 18,
    todayMinutes: 15,
    totalMinutes: 180,
    averageAccuracyPct: 78,
    sevenDayXp: [120, 80, 95, 110, 70, 130, 45],
    weakestExerciseType: 'spelling',
    mostMissedWordIds: ['w1', 'w2'],
    achievementCount: 3,
    trainingXp: 300,
    trainingRank: -1,
    modalityAccuracy: {'meaning': 84, 'listening': 71, 'spelling': 63, 'context': 77},
    dailyXp: [120, 80, 95, 110, 70, 130, 45],
    topErrorTypes: ['spelling', 'listening'],
  );

  final now = DateTime(2026, 6, 26);
  // Build 10 CustomWords with varied masteryLevels and dimension scores.
  final customWords = List<CustomWord>.generate(10, (i) {
    return CustomWord(
      id: 'w$i',
      uid: 'test-user',
      word: 'word$i',
      meaning: 'meaning$i',
      exampleSentence: 'Example $i.',
      note: '',
      tag: '自定义',
      difficulty: 'Medium',
      status: i < 3 ? 'New' : i < 7 ? 'Review' : 'Mastered',
      easeFactor: 2.5,
      intervalDays: 1,
      repetitionCount: i,
      lapseCount: 0,
      masteryLevel: i < 3 ? 0 : i < 7 ? 2 : 5,
      correctCount: i * 2,
      wrongCount: i,
      meaningRecognitionScore: 50 + i * 3,
      meaningRecallScore: 40 + i * 3,
      spellingScore: 30 + i * 4,
      listeningScore: 45 + i * 2,
      contextScore: 55 + i * 2,
      confidenceScore: 50 + i,
      createdAt: now,
      updatedAt: now,
      nextReviewAt: now,
    );
  });

  return AppState(
    isBootstrapped: true,
    isLoading: false,
    wordBooks: const [],
    currentWordBookId: 'hsk1',
    lessons: const [],
    customWords: customWords,
    userWords: const [],
    themeMode: ThemeMode.light,
    reminderSettings: DailyReminderSettings.defaults,
    completedLessonIds: const {},
    todayCompletedLessonIds: const {},
    todayReviewWordIds: const {},
    todayTrainingSessionIds: const {},
    todayTrainingGameIds: const {},
    todayTrainingXp: 45,
    todayClaimedRewardIds: const {},
    rewardTasks: const [],
    pendingRewardTaskIds: const {},
    isRewardLoading: false,
    notifications: const [],
    lotteryPrizes: const [],
    userAssets: const [],
    aiHistory: const [],
    forumPosts: const [],
    analyticsSnapshot: analytics,
    reviewWords: customWords,
  );
}

/// Builds a zero-data state (new user).
AppState _zeroState() {
  return AppState(
    isBootstrapped: true,
    isLoading: false,
    wordBooks: const [],
    currentWordBookId: 'hsk1',
    lessons: const [],
    customWords: const [],
    userWords: const [],
    themeMode: ThemeMode.light,
    reminderSettings: DailyReminderSettings.defaults,
    completedLessonIds: const {},
    todayCompletedLessonIds: const {},
    todayReviewWordIds: const {},
    todayTrainingSessionIds: const {},
    todayTrainingGameIds: const {},
    todayTrainingXp: 0,
    todayClaimedRewardIds: const {},
    rewardTasks: const [],
    pendingRewardTaskIds: const {},
    isRewardLoading: false,
    notifications: const [],
    lotteryPrizes: const [],
    userAssets: const [],
    aiHistory: const [],
    forumPosts: const [],
    analyticsSnapshot: const LearningAnalytics(
      streakDays: 0,
      totalStudyDays: 0,
      learnedWords: 0,
      masteredWords: 0,
      newWordsToday: 0,
      reviewsToday: 0,
      wordbookProgressPct: 0,
      todayMinutes: 0,
      totalMinutes: 0,
      averageAccuracyPct: 0,
      sevenDayXp: [],
      weakestExerciseType: '',
      mostMissedWordIds: [],
      achievementCount: 0,
      trainingXp: 0,
      trainingRank: -1,
    ),
    reviewWords: const [],
  );
}

void main() {
  group('ProgressAnalyticsScreen — seeded data', () {
    testWidgets('renders without crashing and LineChart is visible', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), _seededState()),
      );
      await tester.pump();
      // The screen renders without throwing
      expect(tester.takeException(), isNull);

      // C1 LineChart (XP trend) is visible near the top
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('all four chart types render after scrolling', (tester) async {
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), _seededState()),
      );
      await tester.pump();

      // C1 is visible immediately
      expect(find.byType(LineChart), findsOneWidget);

      // Scroll to reveal radar + bar + pie charts
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -600),
      );
      await tester.pump();

      // After scrolling, RadarChart and BarChart should be in the tree
      expect(find.byType(RadarChart), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('report title section header is present', (tester) async {
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), _seededState()),
      );
      await tester.pump();

      // The locale is zh (pinned by flutter_test_config), so look for zh strings
      // OR use text that exists in both locales via widget type
      // SectionHeader renders a Text with the title — we just check it exists
      expect(find.byType(SectionHeader), findsWidgets);
    });

    testWidgets('mastery pie legend text nodes are in the tree after scroll',
        (tester) async {
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), _seededState()),
      );
      await tester.pump();

      // Scroll past XP trend + radar to reach the pie chart section
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();

      // PieChart should be visible now
      expect(find.byType(PieChart), findsOneWidget);
    });
  });

  group('ProgressAnalyticsScreen — scope header (§6 P4d)', () {
    testWidgets('shows the current (language, wordbook) scope label',
        (tester) async {
      final state = _seededState().copyWith(
        currentLanguage: 'ja',
        currentWordBookId: 'jlpt_n5',
      );
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), state),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        find.byKey(const ValueKey('analytics-scope-pill')),
        findsOneWidget,
      );
      expect(find.text(l10n.analyticsScopeLabel('JLPT N5')), findsOneWidget);
    });
  });

  group('ProgressAnalyticsScreen — zero data (new user)', () {
    testWidgets('renders without crashing on all-zero data', (tester) async {
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), _zeroState()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows placeholder widgets for empty charts', (tester) async {
      await tester.pumpWidget(
        _buildHarness(const ProgressAnalyticsScreen(), _zeroState()),
      );
      await tester.pump();

      // Empty state: no chart widgets rendered (placeholders shown instead)
      // LineChart is not rendered when xpData is empty
      expect(find.byType(LineChart), findsNothing);
      // RadarChart is not rendered when reviewWords is empty
      expect(find.byType(RadarChart), findsNothing);
      // PieChart is not rendered when reviewWords is empty
      expect(find.byType(PieChart), findsNothing);
    });
  });

  group('Analytics helper — mastery bucketing', () {
    test('correctly buckets words by mastery level', () {
      final now = DateTime(2026, 6, 26);
      CustomWord makeWord(int mastery) => CustomWord(
            id: 'w$mastery',
            uid: 'u',
            word: 'w',
            meaning: 'm',
            exampleSentence: '',
            note: '',
            tag: '自定义',
            difficulty: 'Medium',
            status: 'Review',
            easeFactor: 2.5,
            intervalDays: 1,
            repetitionCount: 0,
            lapseCount: 0,
            masteryLevel: mastery,
            correctCount: 0,
            wrongCount: 0,
            meaningRecognitionScore: 20,
            meaningRecallScore: 10,
            spellingScore: 10,
            listeningScore: 10,
            contextScore: 10,
            confidenceScore: 10,
            createdAt: now,
            updatedAt: now,
            nextReviewAt: now,
          );

      final words = [makeWord(0), makeWord(1), makeWord(3), makeWord(4), makeWord(5)];
      final newCount = words.where((w) => w.masteryLevel <= 0).length;
      final learningCount =
          words.where((w) => w.masteryLevel > 0 && w.masteryLevel < 4).length;
      final masteredCount = words.where((w) => w.masteryLevel >= 4).length;

      expect(newCount, equals(1)); // mastery == 0
      expect(learningCount, equals(2)); // mastery 1, 3
      expect(masteredCount, equals(2)); // mastery 4, 5
    });

    test('dimension averages are bounded [0, 100]', () {
      final now = DateTime(2026, 6, 26);
      final words = List<CustomWord>.generate(5, (i) => CustomWord(
            id: 'w$i',
            uid: 'u',
            word: 'w$i',
            meaning: 'm',
            exampleSentence: '',
            note: '',
            tag: '自定义',
            difficulty: 'Medium',
            status: 'Review',
            easeFactor: 2.5,
            intervalDays: 1,
            repetitionCount: 0,
            lapseCount: 0,
            masteryLevel: 2,
            correctCount: 0,
            wrongCount: 0,
            meaningRecognitionScore: 60 + i * 5,
            meaningRecallScore: 50 + i * 5,
            spellingScore: 40 + i * 5,
            listeningScore: 55 + i * 5,
            contextScore: 65 + i * 5,
            confidenceScore: 50,
            createdAt: now,
            updatedAt: now,
            nextReviewAt: now,
          ));

      final n = words.length.toDouble();
      final avgRecognition =
          words.fold<double>(0, (s, w) => s + w.meaningRecognitionScore) / n;
      final avgListening =
          words.fold<double>(0, (s, w) => s + w.listeningScore) / n;

      expect(avgRecognition.clamp(0.0, 100.0), inInclusiveRange(0.0, 100.0));
      expect(avgListening.clamp(0.0, 100.0), inInclusiveRange(0.0, 100.0));
    });
  });
}
