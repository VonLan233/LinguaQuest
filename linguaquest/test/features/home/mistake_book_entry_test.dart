// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/features/home/home_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// 最小 FakeAppController：直接返回固定 AppState，不依赖任何 repository。
/// 遵循 test/features/home/home_menu_icon_test.dart 和
/// test/features/quests/progress_analytics_screen_test.dart 中的既有模式。
class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;

  @override
  AppState build() => _state;
}

/// 构建最小测试 harness：ProviderScope + MaterialApp + l10n + HomeScreen。
/// GoRouter 无需配置——HomeScreen 的 context.push 只在回调里调用，不影响 pump。
Widget _buildHarness(AppState state) {
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(() => _FakeAppController(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const Scaffold(body: HomeScreen()),
    ),
  );
}

/// 创建一个满足 isWeak == true 的 CustomWord（status == 'Relearning'）。
CustomWord _makeWeakWord(int i) {
  final now = DateTime(2026, 6, 29);
  return CustomWord(
    id: 'w$i',
    uid: 'test-uid',
    word: 'word$i',
    meaning: 'meaning$i',
    exampleSentence: 'Example $i.',
    note: '',
    tag: '自定义',
    difficulty: 'Medium',
    status: 'Relearning', // isWeak == true：status == 'Relearning'
    easeFactor: 2.5,
    intervalDays: 1,
    repetitionCount: 0,
    lapseCount: 0,
    masteryLevel: 0,
    correctCount: 0,
    wrongCount: 2,
    meaningRecognitionScore: 20,
    meaningRecallScore: 20,
    spellingScore: 20,
    listeningScore: 20,
    contextScore: 20,
    confidenceScore: 20,
    createdAt: now,
    updatedAt: now,
    nextReviewAt: now,
  );
}

/// 构造包含指定数量弱项词的 AppState。
/// weakWords getter 从 reviewWords 中过滤 isWeak == true 的词；
/// 直接向 AppState 构造函数传入 reviewWords 绕过 copyWith 的限制。
AppState _makeState({required int weakWordCount}) {
  final weakWords = List<CustomWord>.generate(weakWordCount, _makeWeakWord);
  return AppState(
    isBootstrapped: true,
    isLoading: false,
    wordBooks: const [],
    currentWordBookId: 'hsk1',
    lessons: const [],
    customWords: weakWords,
    userWords: const [],
    themeMode: ThemeMode.light,
    reminderSettings: DailyReminderSettings.defaults,
    completedLessonIds: const {},
    todayCompletedLessonIds: const {},
    todayLearnedWordIds: const {},
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
    reviewWords: weakWords, // 直接注入，使 weakWords getter 返回 weakWordCount 个词
  );
}

void main() {
  testWidgets('weakWords > 3 时显示查看全部按钮', (tester) async {
    // 设置足够大的视口，避免 ListView 惰性构建导致按钮不在树中
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildHarness(_makeState(weakWordCount: 4)));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('home-see-all-mistakes')),
      findsOneWidget,
    );
  });

  testWidgets('weakWords <= 3 时不显示查看全部按钮', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildHarness(_makeState(weakWordCount: 3)));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('home-see-all-mistakes')),
      findsNothing,
    );
  });
}
