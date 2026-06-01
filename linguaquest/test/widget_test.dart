import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/widgets/learning_badges.dart';
import 'package:linguaquest/core/widgets/pronunciation_controls.dart';
import 'package:linguaquest/data/models/activity_summary.dart';
import 'package:linguaquest/data/models/achievement.dart';
import 'package:linguaquest/data/models/ai_conversation.dart';
import 'package:linguaquest/data/models/app_notification.dart';
import 'package:linguaquest/data/models/analytics_summary.dart';
import 'package:linguaquest/data/models/class_group.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/forum_post.dart';
import 'package:linguaquest/data/models/leaderboard_entry.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/lesson_result.dart';
import 'package:linguaquest/data/models/lottery_draw.dart';
import 'package:linguaquest/data/models/review_event.dart';
import 'package:linguaquest/data/models/reward_task.dart';
import 'package:linguaquest/data/models/study_session.dart';
import 'package:linguaquest/data/models/target_word_progress.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/repositories/app_services_repository.dart';
import 'package:linguaquest/data/repositories/custom_word_repository.dart';
import 'package:linguaquest/data/repositories/learning_repository.dart';
import 'package:linguaquest/data/repositories/review_repository.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/features/auth/goal_setup_screen.dart';
import 'package:linguaquest/features/learning/lesson_preview_screen.dart';
import 'package:linguaquest/features/quiz/lesson_result_screen.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
import 'package:linguaquest/features/search/search_screen.dart';
import 'package:linguaquest/features/wordbook/target_word_detail_screen.dart';
import 'package:linguaquest/features/wordbook/word_detail_screen.dart';
import 'package:linguaquest/features/wordbook/wordbook_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/lesson_fixtures.dart';

Widget _testApp({
  Widget? child,
  AuthRepository? authRepository,
  CustomWordRepository? customWordRepository,
  LearningRepository? learningRepository,
  ReviewRepository? reviewRepository,
  AppServicesRepository? appServicesRepository,
}) {
  return ProviderScope(
    overrides: _testOverrides(
      authRepository: authRepository,
      customWordRepository: customWordRepository,
      learningRepository: learningRepository,
      reviewRepository: reviewRepository,
      appServicesRepository: appServicesRepository,
    ),
    child: child ?? const LinguaQuestApp(),
  );
}

ProviderContainer _testContainer({
  AuthRepository? authRepository,
  CustomWordRepository? customWordRepository,
  LearningRepository? learningRepository,
  ReviewRepository? reviewRepository,
  AppServicesRepository? appServicesRepository,
}) {
  return ProviderContainer(
    overrides: _testOverrides(
      authRepository: authRepository,
      customWordRepository: customWordRepository,
      learningRepository: learningRepository,
      reviewRepository: reviewRepository,
      appServicesRepository: appServicesRepository,
    ),
  );
}

List<Override> _testOverrides({
  AuthRepository? authRepository,
  CustomWordRepository? customWordRepository,
  LearningRepository? learningRepository,
  ReviewRepository? reviewRepository,
  AppServicesRepository? appServicesRepository,
}) {
  return [
    authRepositoryProvider.overrideWithValue(
      authRepository ?? _PrefsAuthRepository(),
    ),
    customWordRepositoryProvider.overrideWithValue(
      customWordRepository ?? _MemoryCustomWordRepository(),
    ),
    learningRepositoryProvider.overrideWithValue(
      learningRepository ?? _FileLearningRepository(),
    ),
    reviewRepositoryProvider.overrideWithValue(
      reviewRepository ?? _MemoryReviewRepository(),
    ),
    appServicesRepositoryProvider.overrideWithValue(
      appServicesRepository ?? _MemoryAppServicesRepository(),
    ),
  ];
}

Future<void> _settleBoot(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts at onboarding when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    expect(find.text('LinguaQuest'), findsWidgets);
    expect(find.text('清晰路径'), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('注册账号'), findsOneWidget);
  });

  testWidgets('renders redesigned home dashboard for an existing learner', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'widget-user',
      name: 'Ava',
      email: 'ava@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    expect(find.text('已连续打卡 6 天'), findsOneWidget);
    expect(find.text('雅思核心词汇 · 中级'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('训练场'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('今日词条'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('今日词条'), findsOneWidget);
  });

  testWidgets('home progress uses the combined new and review target', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'progress-user',
      name: 'Ava',
      email: 'progress@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
      'linguaquest.today.date': _todayDateKey(DateTime.now()),
      'linguaquest.today.lessons': ['ielts-lesson-1'],
      'linguaquest.today.reviews': ['seed-1'],
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    expect(find.text('今天完成 4/14 词'), findsOneWidget);
    expect(find.text('29%'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);

    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator).first,
    );
    expect(progress.value, closeTo(4 / 14, 0.001));
  });

  testWidgets('home search bar opens search instead of wordbook', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'search-entry-user',
      name: 'Sera',
      email: 'sera@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.tap(find.text('搜索单词、短语或例句'));
    await tester.pumpAndSettle();

    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('输入关键词开始搜索'), findsOneWidget);
    expect(find.text('单词库'), findsNothing);
  });

  testWidgets('home word of day opens its target word detail', (tester) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'word-of-day-user',
      name: 'Wendy',
      email: 'wendy@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('今日词条'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日词条'));
    await tester.pumpAndSettle();

    expect(find.text('cancel'), findsWidgets);
    expect(find.text('加入生词本'), findsOneWidget);
    expect(find.text('当前计划中'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('AI 学习'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('AI 学习'), findsOneWidget);
    expect(find.text('词组搭配'), findsOneWidget);
    expect(find.text('近义 / 反义'), findsOneWidget);
  });

  test('word initial cue falls back for empty custom words', () {
    expect(wordInitialCue(''), '?');
    expect(wordInitialCue('  '), '?');
    expect(wordInitialCue('apple'), 'A');
  });

  testWidgets('pronunciation controls expose loading and retry states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: PronunciationControls(word: '')),
      ),
    );

    expect(find.text('英音'), findsOneWidget);
    expect(find.text('美音'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pronunciation-uk')));
    await tester.pump();

    expect(find.text('英音加载'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 430));
    await tester.pump();

    expect(find.text('英音重试'), findsOneWidget);
    expect(find.text('英音发音失败，请重试'), findsWidgets);
  });

  testWidgets('home new-study entry opens standalone new learning flow', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'hero-user',
      name: 'Hero',
      email: 'hero@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('新学 12'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 12'));
    await tester.pumpAndSettle();

    expect(find.text('今日新词包'), findsOneWidget);
    expect(find.text('进入词卡学习'), findsOneWidget);
    expect(find.text('检查'), findsNothing);
  });

  testWidgets('home review entry opens standalone review flow', (tester) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'review-user',
      name: 'Riley',
      email: 'riley@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('复习 2'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '复习 2'));
    await tester.pumpAndSettle();

    expect(find.text('今日复习'), findsOneWidget);
    expect(find.text('记住了'), findsOneWidget);
    expect(find.text('没记住'), findsOneWidget);
    expect(find.text('显示释义'), findsNothing);
    expect(find.text('加入错词卡'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '没记住'));
    await tester.pumpAndSettle();

    expect(find.text('加入巩固队列'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '加入巩固队列'));
    await tester.pumpAndSettle();

    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('ambiguous'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '记住了'));
    await tester.pumpAndSettle();

    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('resilient'), findsOneWidget);
  });

  testWidgets('review flow confirms before leaving after progress', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'review-exit-user',
      name: 'Rina',
      email: 'rina@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('复习 2'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '复习 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '没记住'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('离开复习？'), findsOneWidget);
    expect(find.text('已完成的词卡已经保存；未完成的词仍会保留在复习队列。'), findsOneWidget);

    await tester.tap(find.text('继续复习'));
    await tester.pumpAndSettle();

    expect(find.text('今日复习'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '离开'));
    await tester.pumpAndSettle();

    expect(find.text('今日任务控制台'), findsOneWidget);
  });

  testWidgets('discover check-in only counts same-day study', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final profile = UserProfile(
      uid: 'discover-user',
      name: 'Dina',
      email: 'dina@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 120,
      streak: 4,
      lastStudyDate: yesterday,
      createdAt: yesterday,
      updatedAt: yesterday,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();

    expect(find.text('每日签到'), findsOneWidget);
    expect(find.text('XP 用途'), findsOneWidget);
    expect(find.text('去完成 +5 XP'), findsOneWidget);
    expect(find.textContaining('已入账'), findsNothing);
  });

  testWidgets(
    'training completion does not unlock formal new-learning reward',
    (tester) async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'training-split-user',
        name: 'Tia',
        email: 'tia@lingua.quest',
        targetExam: 'IELTS',
        level: 'Intermediate',
        dailyGoal: 12,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });
      final container = _testContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final campusLesson = seedLessons().last;
      await container
          .read(appControllerProvider.notifier)
          .completeLesson(
            LessonResult(
              lessonId: campusLesson.id,
              lessonTitle: campusLesson.title,
              totalQuestions: campusLesson.questions.length,
              correctAnswers: campusLesson.questions.length,
              xpEarned: 8,
              mistakes: const [],
              completedAt: DateTime.now(),
            ),
          );

      final state = container.read(appControllerProvider);
      expect(state.todayCompletedLessonIds, contains(campusLesson.id));
      expect(state.todayCompletedFormalLessonIds, isEmpty);
      expect(state.todayLearningWords, 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LinguaQuestApp(),
        ),
      );
      await _settleBoot(tester);

      await tester.tap(find.text('发现'));
      await tester.pumpAndSettle();

      final newLearningTask = find.ancestor(
        of: find.text('完成新学'),
        matching: find.byType(InkWell),
      );
      expect(newLearningTask, findsOneWidget);
      expect(
        find.descendant(of: newLearningTask, matching: find.text('去完成 +12 XP')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: newLearningTask, matching: find.text('领取 +12 XP')),
        findsNothing,
      );
    },
  );

  testWidgets('discover weak cleanup does not auto-complete without mistakes', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'clean-discover-user',
      name: 'Cleo',
      email: 'cleo@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 120,
      streak: 4,
      createdAt: now,
      updatedAt: now,
    );
    final customWordRepository = _ConcurrentCustomWordRepository()
      ..words.add(
        CustomWord.create(
          id: 'stable-word',
          uid: profile.uid,
          word: 'stable',
          meaning: '稳定的',
          exampleSentence: 'Stable progress compounds over time.',
          now: now,
        ).copyWith(masteryLevel: 4, status: 'Review'),
      );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(
      _testApp(customWordRepository: customWordRepository),
    );
    await _settleBoot(tester);

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('错词清理'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final cleanupTask = find.ancestor(
      of: find.text('错词清理'),
      matching: find.byType(InkWell),
    );
    expect(cleanupTask, findsOneWidget);
    expect(
      find.descendant(of: cleanupTask, matching: find.text('去完成 +8 XP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cleanupTask, matching: find.textContaining('已入账')),
      findsNothing,
    );
  });

  testWidgets('discover weak cleanup waits until all weak words are clear', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'partial-cleanup-user',
      name: 'Poe',
      email: 'poe@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 120,
      streak: 4,
      createdAt: now,
      updatedAt: now,
    );
    final customWordRepository = _ConcurrentCustomWordRepository()
      ..words.addAll([
        CustomWord.create(
          id: 'cleared-word',
          uid: profile.uid,
          word: 'cleared',
          meaning: '已清理',
          exampleSentence: 'One mistake was cleared today.',
          now: now,
        ).copyWith(
          masteryLevel: 2,
          status: 'Review',
          correctCount: 3,
          wrongCount: 1,
        ),
        CustomWord.create(
          id: 'still-weak-word',
          uid: profile.uid,
          word: 'fragile',
          meaning: '脆弱的',
          exampleSentence: 'This word is still weak.',
          now: now,
        ).copyWith(
          masteryLevel: 1,
          status: 'Learning',
          correctCount: 1,
          wrongCount: 3,
        ),
      ]);
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
      'linguaquest.today.date': DateTime.now()
          .toIso8601String()
          .split('T')
          .first,
      'linguaquest.today.reviews': ['cleared-word'],
    });

    await tester.pumpWidget(
      _testApp(customWordRepository: customWordRepository),
    );
    await _settleBoot(tester);

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('错词清理'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final cleanupTask = find.ancestor(
      of: find.text('错词清理'),
      matching: find.byType(InkWell),
    );
    expect(cleanupTask, findsOneWidget);
    expect(
      find.descendant(of: cleanupTask, matching: find.text('去完成 +8 XP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cleanupTask, matching: find.textContaining('已入账')),
      findsNothing,
    );
  });

  testWidgets('failed login stays on login screen and shows error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_testApp(authRepository: _FailingAuth()));
    await _settleBoot(tester);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('learner@lingua.quest'), findsNothing);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'learner@lingua.quest',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.textContaining('login failed'), findsOneWidget);
    expect(find.textContaining('已连续打卡'), findsNothing);
  });

  testWidgets('bootstrap failure can retry without restarting the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final learningRepository = _FlakyLearningRepository();

    await tester.pumpWidget(_testApp(learningRepository: learningRepository));
    await _settleBoot(tester);

    expect(learningRepository.listAttempts, 1);
    expect(find.textContaining('LinguaQuest 启动失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await _settleBoot(tester);

    expect(learningRepository.listAttempts, 2);
    expect(find.byIcon(Icons.route_outlined), findsWidgets);
  });

  testWidgets('main shell supports deliberate horizontal tab swiping', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'swipe-user',
      name: 'Ari',
      email: 'ari@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.fling(find.text('今日任务控制台'), const Offset(-24, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('今日任务控制台'), findsOneWidget);

    await tester.drag(find.text('今日任务控制台'), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(find.text('限时测试'), findsOneWidget);
  });

  testWidgets('main shell fling direction matches drag direction', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'fling-user',
      name: 'Finn',
      email: 'finn@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.fling(find.text('今日任务控制台'), const Offset(-80, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('限时测试'), findsOneWidget);
  });

  testWidgets('dark theme keeps headline text readable', (tester) async {
    final dark = AppTheme.dark();
    final headlineColor = dark.textTheme.headlineMedium?.color;

    expect(headlineColor, isNotNull);
    expect(headlineColor, isNot(Colors.black));
  });

  testWidgets('goal setup choices keep a stable size when selected', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      _testApp(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GoalSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dailyEnglish = find.byKey(const ValueKey('choice-Daily English'));
    final businessEnglish = find.byKey(const ValueKey('choice-SAT'));

    final dailyEnglishSize = tester.getSize(dailyEnglish);
    final businessEnglishSize = tester.getSize(businessEnglish);

    await tester.scrollUntilVisible(
      businessEnglish,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(businessEnglish);
    await tester.pumpAndSettle();

    expect(tester.getSize(dailyEnglish), dailyEnglishSize);
    expect(tester.getSize(businessEnglish), businessEnglishSize);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await tester.pumpAndSettle();

    final visibleElementary = find.byKey(const ValueKey('choice-Elementary'));
    final visibleAdvanced = find.byKey(const ValueKey('choice-Advanced'));
    final elementarySize = tester.getSize(visibleElementary);
    final advancedSize = tester.getSize(visibleAdvanced);

    await tester.tap(visibleAdvanced);
    await tester.pumpAndSettle();

    expect(tester.getSize(visibleElementary), elementarySize);
    expect(tester.getSize(visibleAdvanced), advancedSize);
  });

  testWidgets('goal setup starts from the current learning profile', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'goal-current-user',
      name: 'Gina',
      email: 'gina@lingua.quest',
      targetExam: 'IELTS',
      level: 'Advanced',
      dailyGoal: 15,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('学习模式'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('学习模式'));
    await tester.pumpAndSettle();

    expect(find.text('目标设置'), findsOneWidget);
    expect(find.text('雅思核心词汇'), findsWidgets);
    expect(find.text('15/天'), findsOneWidget);
    expect(find.text('当前词书'), findsOneWidget);
    expect(find.text('雅思核心词汇 · 已学 0/160 词'), findsOneWidget);
    expect(find.text('新学 15 词'), findsOneWidget);
    expect(find.text('复习上限 30 词'), findsOneWidget);
    expect(find.text('查看完整词汇表'), findsOneWidget);
  });

  test('deadline picker initial date stays inside selectable bounds', () {
    final now = DateTime(2026, 5, 25, 15, 45);
    final today = DateTime(2026, 5, 25);
    final fallback = DateTime(2026, 6, 24);
    final lastDate = DateTime(2027, 5, 25);

    expect(
      clampDeadlinePickerInitialDate(now: now, selected: DateTime(2026, 5, 1)),
      fallback,
    );
    expect(
      clampDeadlinePickerInitialDate(
        now: now,
        selected: DateTime(2026, 5, 25, 23, 59),
      ),
      today,
    );
    expect(
      clampDeadlinePickerInitialDate(now: now, selected: DateTime(2030, 1, 1)),
      lastDate,
    );
    expect(clampDeadlinePickerInitialDate(now: now), fallback);
  });

  test('learning plan day count uses calendar days', () {
    final plan = LearningPlan(
      target: 'Daily English',
      deadline: DateTime(2026, 5, 27, 23, 59),
      dailyWords: 10,
      remainingWords: 30,
      createdAt: DateTime(2026, 5, 25, 12),
    );

    expect(plan.daysLeft(DateTime(2026, 5, 25, 23, 30)), 3);
  });

  testWidgets('dark semantic surfaces keep readable contrast', (tester) async {
    late Color warmSurface;
    late Color accentSurface;
    late Color selectedSurface;
    late Color onSurface;
    late Color onSelectedSurface;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            warmSurface = AppTheme.warmSurface(context);
            accentSurface = AppTheme.accentSurface(context);
            selectedSurface = AppTheme.selectedSurface(context);
            onSurface = scheme.onSurface;
            onSelectedSurface = scheme.onPrimaryContainer;

            return Scaffold(
              body: Column(
                children: [
                  Container(
                    color: warmSurface,
                    padding: const EdgeInsets.all(12),
                    child: const Text('Warm surface text'),
                  ),
                  Container(
                    color: accentSurface,
                    padding: const EdgeInsets.all(12),
                    child: const Text('Accent surface text'),
                  ),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: AppTheme.progressTrack(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(_contrastRatio(onSurface, warmSurface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(onSurface, accentSurface), greaterThanOrEqualTo(4.5));
    expect(
      _contrastRatio(onSelectedSurface, selectedSurface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('seed learning path contains the PRD lesson range', () {
    final lessons = seedLessons();
    final firstLessonTypes = {
      for (final question in lessons.first.questions) question.type,
    };
    final allQuestionTypes = {
      for (final question in lessons.expand((lesson) => lesson.questions))
        question.type,
    };
    final choiceQuestions = lessons
        .expand((lesson) => lesson.questions)
        .where((question) => question.type != QuizQuestionType.spelling);

    expect(lessons, hasLength(greaterThanOrEqualTo(6)));
    expect(lessons, hasLength(lessThanOrEqualTo(10)));
    expect(
      firstLessonTypes,
      containsAll({
        QuizQuestionType.meaningChoice,
        QuizQuestionType.chineseChoice,
        QuizQuestionType.contextChoice,
        QuizQuestionType.spelling,
      }),
    );
    expect(
      allQuestionTypes,
      containsAll({
        QuizQuestionType.listeningWordChoice,
        QuizQuestionType.listeningMeaningChoice,
      }),
    );
    for (final question in choiceQuestions) {
      expect(question.options, hasLength(4));
      expect(question.options.toSet(), hasLength(4));
      expect(question.options, contains(question.answer));
    }
  });

  test('formal wordbook follows the selected learning target', () {
    final lessons = seedLessons();
    final now = DateTime(2026, 5, 25);

    AppState stateFor(String target) => AppState.initial().copyWith(
      lessons: lessons,
      user: UserProfile(
        uid: 'target-user-$target',
        name: 'Target User',
        email: '$target@lingua.quest',
        targetExam: target,
        level: 'Elementary',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final examState = stateFor('IELTS');
    expect(examState.currentLesson?.id, 'lesson-exam-1');
    expect(examState.formalLessons.map((lesson) => lesson.section).toSet(), {
      '考试高频',
    });

    final dailyState = stateFor('Daily English');
    expect(dailyState.currentLesson?.id, 'lesson-food-1');
    expect(dailyState.formalLessons.map((lesson) => lesson.section).toSet(), {
      '日常英语',
    });

    final businessState = stateFor('Business English');
    expect(businessState.currentLesson?.id, 'lesson-work-1');
    expect(
      businessState.formalLessons.map((lesson) => lesson.section).toSet(),
      {'商务英语'},
    );

    expect(
      dailyState.formalLessons.any((lesson) => lesson.id == 'lesson-campus-1'),
      false,
    );
  });

  test('training packs stay out of formal learning progress', () {
    final lessons = seedLessons();
    final formalLessonIds = {
      for (final lesson in lessons)
        if (!lesson.isTrainingPack) lesson.id,
    };
    final state = AppState.initial().copyWith(
      lessons: lessons,
      completedLessonIds: formalLessonIds,
    );

    expect(
      state.formalLessons.any((lesson) => lesson.id == 'lesson-campus-1'),
      false,
    );
    expect(
      state.totalLearningWords,
      lessons
          .where((lesson) => !lesson.isTrainingPack)
          .fold(0, (total, lesson) => total + lesson.words.length),
    );
    expect(state.completedLearningWords, state.totalLearningWords);
    expect(state.learningPathProgress, 1);
    expect(state.currentLesson?.id, isNot('lesson-campus-1'));
  });

  testWidgets('wordbook and search hide training-only target words', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'formal-wordbook-user',
      name: 'Faye',
      email: 'faye@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final state = container.read(appControllerProvider);
    final fullTargetCount = state.lessons.fold<int>(
      0,
      (total, lesson) => total + lesson.words.length,
    );
    expect(fullTargetCount, greaterThan(state.totalLearningWords));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WordbookScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('${state.totalLearningWords} 个目标词'), findsOneWidget);
    expect(find.text('$fullTargetCount 个目标词'), findsNothing);
    expect(find.text('abandon'), findsWidgets);
    expect(find.text('allocate'), findsNothing);
    expect(find.text('commute'), findsNothing);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'commute');
    await tester.pumpAndSettle();

    expect(find.text('没有找到结果'), findsOneWidget);
    expect(find.text('添加生词'), findsOneWidget);
  });

  testWidgets('lesson preview does not open training-only timed packs', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'training-preview-user',
      name: 'Pax',
      email: 'pax@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final trainingLessonId = container
        .read(appControllerProvider)
        .lessons
        .firstWhere((lesson) => lesson.isTrainingPack)
        .id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: LessonPreviewScreen(lessonId: trainingLessonId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有找到这节课'), findsOneWidget);
    expect(find.text('新学词卡'), findsNothing);
  });

  testWidgets('regular quiz cannot open training-only timed packs', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'training-quiz-user',
      name: 'Quinn',
      email: 'quinn@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final trainingLessonId = container
        .read(appControllerProvider)
        .lessons
        .firstWhere((lesson) => lesson.isTrainingPack)
        .id;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: QuizSessionScreen(lessonId: trainingLessonId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有找到这节课'), findsOneWidget);
    expect(find.text('限时测试'), findsNothing);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: QuizSessionScreen(
            lessonId: trainingLessonId,
            mode: QuizSessionMode.timed,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('限时测试'), findsOneWidget);
    expect(find.text('没有找到这节课'), findsNothing);
  });

  testWidgets(
    'timed test result returns to training instead of learning path',
    (tester) async {
      final lesson = seedLessons().firstWhere((item) => item.isTrainingPack);
      final result = LessonResult(
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        totalQuestions: lesson.questions.length,
        correctAnswers: lesson.questions.length,
        xpEarned: lesson.xpReward,
        mistakes: const [],
        completedAt: DateTime(2026, 5, 25),
      );

      await tester.pumpWidget(
        _testApp(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: LessonResultScreen(
              result: result,
              source: LessonResultSource.timed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('限时测试结果'), findsOneWidget);
      expect(find.text('返回训练场'), findsOneWidget);
      expect(find.text('返回学习路径'), findsNothing);
      expect(find.text('课程结果'), findsNothing);
    },
  );

  testWidgets('lesson mistake appears in review center after result', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'mistake-user',
      name: 'Mia',
      email: 'mia@lingua.quest',
      targetExam: 'IELTS',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入词卡学习'));
    await tester.pumpAndSettle();
    await _completeNewWordCards(tester);

    await tester.tap(find.text('爆炸的， 爆发的'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再试一次'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消， 废除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('explosive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('准备， 预备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'prepare');
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(find.text('答对 3/4 题 · 已入账 +17 XP · 错题已进入复习。'), findsOneWidget);
    expect(find.text('已入账 +17 XP'), findsOneWidget);
    expect(find.text('刚刚到账 +17 XP'), findsOneWidget);
    expect(find.text('总积分 17 XP'), findsOneWidget);
    expect(find.text('当前总积分 17 XP。XP 会同步到个人主页、排行榜和发现页抽奖余额。'), findsOneWidget);
    expect(find.text('查看 XP 用途'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('去复习中心'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('去复习中心'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('cancel'), findsWidgets);
    expect(find.text('课程'), findsWidgets);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsWidgets);
    expect(find.text('复习'), findsWidgets);
  });

  testWidgets('quiz feedback stays visible before continuing', (tester) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'feedback-user',
      name: 'Faye',
      email: 'faye@lingua.quest',
      targetExam: 'IELTS',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入词卡学习'));
    await tester.pumpAndSettle();
    await _completeNewWordCards(tester);

    expect(find.text('英文选义'), findsOneWidget);
    await tester.tap(find.text('取消， 废除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pump();

    Finder continueButton() => find.widgetWithText(FilledButton, '继续');

    expect(find.textContaining('答对了'), findsOneWidget);
    expect(find.textContaining('强化记忆：cancel · 取消， 废除'), findsOneWidget);
    expect(continueButton(), findsOneWidget);
    expect(tester.widget<FilledButton>(continueButton()).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 499));
    expect(tester.widget<FilledButton>(continueButton()).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 2));
    expect(tester.widget<FilledButton>(continueButton()).onPressed, isNotNull);
  });

  testWidgets('lesson and quiz screens expose a working back path', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'back-user',
      name: 'Noah',
      email: 'noah@lingua.quest',
      targetExam: 'IELTS',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入词卡学习'));
    await tester.pumpAndSettle();

    expect(find.text('新学词卡'), findsOneWidget);
    expect(find.text('先判断熟悉度'), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('今日新词包'), findsOneWidget);
    expect(find.text('进入词卡学习'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('今日任务控制台'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入词卡学习'));
    await tester.pumpAndSettle();
    await _completeNewWordCards(tester);

    expect(find.text('检查'), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.text('爆炸的， 爆发的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('离开测验？'), findsOneWidget);

    await tester.tap(find.text('继续答题'));
    await tester.pumpAndSettle();

    expect(find.text('检查'), findsOneWidget);
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();

    final selectedOptionButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('爆炸的， 爆发的'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(selectedOptionButton.onPressed, isNotNull);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('离开'));
    await tester.pumpAndSettle();

    expect(find.text('进入语境练习'), findsWidgets);
  });

  testWidgets('new word cards confirm before leaving after progress', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'word-card-exit-user',
      name: 'Wren',
      email: 'wren@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入词卡学习'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '认识'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('离开词卡？'), findsOneWidget);

    await tester.tap(find.text('继续学习'));
    await tester.pumpAndSettle();

    expect(find.text('新学词卡'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('离开'));
    await tester.pumpAndSettle();

    expect(find.text('今日新词包'), findsOneWidget);
  });

  test('theme and reminder settings persist locally', () async {
    SharedPreferences.setMockInitialValues({});
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    await container
        .read(appControllerProvider.notifier)
        .updateThemeMode(ThemeMode.dark);
    await container
        .read(appControllerProvider.notifier)
        .updateReminderSettings(
          const DailyReminderSettings(enabled: false, hour: 7, minute: 30),
        );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('linguaquest.themeMode'), 'dark');
    expect(
      prefs.getString('linguaquest.reminderSettings'),
      contains('"hour":7'),
    );
    expect(container.read(appControllerProvider).themeMode, ThemeMode.dark);
    expect(
      container.read(appControllerProvider).reminderSettings.enabled,
      false,
    );
  });

  test('test auth repository rejects duplicate email', () async {
    SharedPreferences.setMockInitialValues({});
    final container = _testContainer();
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    expect(
      await controller.register('Ava', 'ava@lingua.quest', 'password123'),
      true,
    );
    expect(
      await controller.register('Ava', 'ava@lingua.quest', 'password123'),
      false,
    );
    expect(
      container.read(appControllerProvider).errorMessage,
      '该邮箱已经注册，请直接登录。',
    );

    await controller.logout();
    expect(
      await controller.register('Ava', 'ava@lingua.quest', 'password123'),
      false,
    );
    expect(
      container.read(appControllerProvider).errorMessage,
      '该邮箱已经注册，请直接登录。',
    );
  });

  test('bootstrap tolerates corrupted persisted settings JSON', () async {
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': 'not-json',
      'linguaquest.reminderSettings': '{bad json',
      'linguaquest.learningPlan': 'not-json',
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final state = container.read(appControllerProvider);

    expect(state.isBootstrapped, true);
    expect(state.errorMessage, isNull);
    expect(state.user, isNull);
    expect(state.reminderSettings, DailyReminderSettings.defaults);
    expect(state.learningPlan, isNull);
  });

  test('logout keeps lesson status and completed ids in sync', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'logout-user',
      name: 'Lou',
      email: 'lou@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    const completedLessonId = 'beginner-lesson-1';
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
      'linguaquest.completedLessons': [completedLessonId],
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    expect(container.read(appControllerProvider).completedLessonIds, {
      completedLessonId,
    });

    await container.read(appControllerProvider.notifier).logout();
    final state = container.read(appControllerProvider);

    expect(state.user, isNull);
    expect(state.completedLessonIds, {completedLessonId});
    expect(state.lessons.first.status, 'completed');
    expect(state.learningPathProgress, greaterThan(0));
  });

  testWidgets('target word detail can add the searched word to custom cards', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'target-save-user',
      name: 'Tara',
      email: 'tara@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final targetWord = container
        .read(appControllerProvider)
        .formalLessons
        .first
        .words
        .first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: TargetWordDetailScreen(wordId: targetWord.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('加入生词本'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '加入生词本'));
    await tester.pumpAndSettle();

    final savedWords = container.read(appControllerProvider).customWords;
    expect(savedWords.any((word) => word.word == targetWord.word), true);
    expect(find.widgetWithText(FilledButton, '已加入生词本'), findsOneWidget);
  });

  testWidgets('custom word detail shows the full knowledge blocks', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'custom-detail-user',
      name: 'Casey',
      email: 'casey@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    await container
        .read(appControllerProvider.notifier)
        .addCustomWord(
          word: 'context',
          meaning: '语境',
          exampleSentence: 'Context helps memory.',
          note: 'Use it in writing.',
          tag: 'study',
          difficulty: 'Medium',
        );
    final word = container.read(appControllerProvider).customWords.first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: WordDetailScreen(wordId: word.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('context'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('词汇全解'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('词汇全解'), findsOneWidget);
    expect(find.text('词组搭配'), findsOneWidget);
    expect(find.text('近义 / 反义'), findsOneWidget);
    expect(find.text('派生词族'), findsOneWidget);
    expect(find.text('词根拆词'), findsOneWidget);
    expect(find.textContaining('related word'), findsNothing);

    await tester.tap(find.text('近义 / 反义'));
    await tester.pumpAndSettle();

    expect(find.textContaining('related word'), findsOneWidget);
  });

  testWidgets('home and wordbook tolerate empty lesson words and tags', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'empty-data-user',
      name: 'Eli',
      email: 'eli@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    final emptyLesson = seedLessons().first.copyWith(
      id: 'empty-lesson',
      title: 'Empty Lesson',
      status: 'current',
      words: const [],
      questions: const [],
    );
    final taglessWord = const Word(
      id: 'tagless-word',
      word: 'context',
      phonetic: '/ˈkɒntekst/',
      meaning: '语境',
      definition: 'The situation in which a word is used.',
      partOfSpeech: 'noun',
      exampleSentence: 'Context helps learners understand meaning.',
      exampleTranslation: '语境帮助学习者理解含义。',
      imageCue: '🧭',
      difficulty: 'Easy',
      tags: [],
    );
    final taglessLesson = seedLessons()[1].copyWith(
      id: 'tagless-lesson',
      title: 'Tagless Lesson',
      status: 'locked',
      words: [taglessWord],
      questions: const [],
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(
      _testApp(
        learningRepository: _StaticLearningRepository([
          emptyLesson,
          taglessLesson,
        ]),
      ),
    );
    await _settleBoot(tester);

    expect(find.text('今日任务控制台'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('打开单词卡片'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('打开单词卡片'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('单词本'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('单词本'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('图片单词本'), findsOneWidget);
    expect(find.text('context'), findsOneWidget);
    expect(find.text('简单'), findsOneWidget);
  });

  test('deadline planning saves daily words into the profile', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'plan-user',
      name: 'Pia',
      email: 'pia@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      createdAt: now,
      updatedAt: now,
      xp: 0,
      streak: 0,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final deadline = DateTime.now().add(const Duration(days: 9));
    final succeeded = await container
        .read(appControllerProvider.notifier)
        .completeGoalSetup(
          targetExam: 'IELTS',
          level: 'Intermediate',
          dailyGoal: 10,
          deadline: deadline,
        );

    final state = container.read(appControllerProvider);
    expect(succeeded, true);
    expect(state.learningPlan, isNotNull);
    expect(state.user?.dailyGoal, state.learningPlan?.dailyWords);
    expect(state.learningPlan?.dailyWords, greaterThan(0));
    expect(state.learningPlan?.remainingWords, state.totalLearningWords);
    expect(
      state.learningPlan?.remainingWords,
      lessThan(
        state.lessons.fold<int>(
          0,
          (total, lesson) => total + lesson.words.length,
        ),
      ),
    );
  });

  test('remembered words cannot be counted twice on the same day', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'review-user',
      name: 'Rae',
      email: 'rae@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      createdAt: now,
      updatedAt: now,
      xp: 0,
      streak: 0,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final dueWord = container.read(appControllerProvider).dueWords.first;

    expect(
      await container
          .read(appControllerProvider.notifier)
          .reviewWord(dueWord.id, true),
      true,
    );
    final reviewedWord = container
        .read(appControllerProvider)
        .customWords
        .firstWhere((word) => word.id == dueWord.id);
    expect(reviewedWord.correctCount, dueWord.correctCount + 1);

    expect(
      await container
          .read(appControllerProvider.notifier)
          .reviewWord(dueWord.id, true),
      false,
    );
    final afterDuplicate = container
        .read(appControllerProvider)
        .customWords
        .firstWhere((word) => word.id == dueWord.id);
    expect(afterDuplicate.correctCount, reviewedWord.correctCount);
  });

  test('claiming a discover reward updates XP once per day', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'reward-user',
      name: 'Rey',
      email: 'rey@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      createdAt: now,
      updatedAt: now,
      xp: 30,
      streak: 1,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final controller = container.read(appControllerProvider.notifier);

    expect(
      await controller.claimReward(
        id: 'daily-checkin',
        points: 5,
        isAvailable: true,
      ),
      true,
    );
    expect(container.read(appControllerProvider).user?.xp, 35);
    expect(
      container.read(appControllerProvider).todayClaimedRewardIds,
      contains('daily-checkin'),
    );

    expect(
      await controller.claimReward(
        id: 'daily-checkin',
        points: 5,
        isAvailable: true,
      ),
      false,
    );
    expect(container.read(appControllerProvider).user?.xp, 35);
  });

  test('custom word review status follows mastery thresholds', () {
    final now = DateTime(2026, 5, 25);
    final word = CustomWord.create(
      id: 'status-word',
      uid: 'status-user',
      word: 'emerge',
      meaning: '出现',
      exampleSentence: 'Patterns emerge after review.',
      now: now,
    );

    expect(word.reviewed(isCorrect: true, now: now).status, 'Learning');
    expect(
      word.copyWith(masteryLevel: 1).reviewed(isCorrect: true, now: now).status,
      'Review',
    );
    expect(
      word.copyWith(masteryLevel: 4).reviewed(isCorrect: true, now: now).status,
      'Mastered',
    );
    expect(word.reviewed(isCorrect: false, now: now).status, 'Relearning');
  });

  testWidgets('spelling retry keeps the previous input for editing', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'spelling-user',
      name: 'Sky',
      email: 'sky@lingua.quest',
      targetExam: 'IELTS',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(_testApp());
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入词卡学习'));
    await tester.pumpAndSettle();
    await _completeNewWordCards(tester);

    await tester.tap(find.text('取消， 废除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('explosive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('准备， 预备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'prepar');
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再试一次'));
    await tester.pumpAndSettle();

    expect(find.text('prepar'), findsOneWidget);
  });

  test(
    'mistake words can be converted into custom cards in one action',
    () async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'cards-user',
        name: 'Kai',
        email: 'kai@lingua.quest',
        targetExam: 'Daily English',
        level: 'Elementary',
        dailyGoal: 10,
        createdAt: now,
        updatedAt: now,
        xp: 0,
        streak: 0,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });
      final container = _testContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final lesson = seedLessons().first;
      final mistake = lesson.questions[1];
      final result = LessonResult(
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        totalQuestions: lesson.questions.length,
        correctAnswers: 2,
        xpEarned: 10,
        mistakes: [mistake],
        completedAt: DateTime.now(),
      );

      expect(
        await container
            .read(appControllerProvider.notifier)
            .completeLesson(result),
        true,
      );
      final added = await container
          .read(appControllerProvider.notifier)
          .addMistakesToCustomWords({mistake.word.id});

      expect(added, 1);
      expect(
        container
            .read(appControllerProvider)
            .customWords
            .any((word) => word.word == mistake.word.word),
        true,
      );
    },
  );

  test('mistake card import creates cards concurrently', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'parallel-cards-user',
      name: 'Par',
      email: 'par@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      createdAt: now,
      updatedAt: now,
      xp: 0,
      streak: 0,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final customWordRepository = _ConcurrentCustomWordRepository();
    final container = _testContainer(
      customWordRepository: customWordRepository,
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final lesson = seedLessons().first;
    final mistakes = List.generate(4, _mistakeQuestion);
    await container
        .read(appControllerProvider.notifier)
        .completeLesson(
          LessonResult(
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            totalQuestions: mistakes.length,
            correctAnswers: 0,
            xpEarned: 10,
            mistakes: mistakes,
            completedAt: DateTime.now(),
          ),
        );

    final added = await container
        .read(appControllerProvider.notifier)
        .addMistakesToCustomWords(mistakes.map((item) => item.word.id).toSet());

    expect(added, 4);
    expect(customWordRepository.maxConcurrentCreates, greaterThan(1));
  });

  testWidgets('mistake card importer preserves an empty manual selection', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'selection-user',
      name: 'Sel',
      email: 'sel@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = _testContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final lesson = seedLessons().first;
    final mistakes = lesson.questions.take(2).toList();
    await container
        .read(appControllerProvider.notifier)
        .completeLesson(
          LessonResult(
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            totalQuestions: lesson.questions.length,
            correctAnswers: 1,
            xpEarned: 10,
            mistakes: mistakes,
            completedAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LinguaQuestApp(),
      ),
    );
    await _settleBoot(tester);

    await tester.scrollUntilVisible(
      find.text('复习 2'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('复习 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('管理复习队列'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('加入错词卡'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('加入已选 (2)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mistake-select-w-allocate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mistake-select-w-evaluate')));
    await tester.pumpAndSettle();
    expect(find.text('加入已选 (0)'), findsOneWidget);

    await container
        .read(appControllerProvider.notifier)
        .updateThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.text('加入已选 (0)'), findsOneWidget);
  });

  testWidgets(
    'mistake card importer only selects visible mistakes by default',
    (tester) async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'visible-selection-user',
        name: 'Vis',
        email: 'vis@lingua.quest',
        targetExam: 'Daily English',
        level: 'Elementary',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });
      final container = _testContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final lesson = seedLessons().first;
      final mistakes = List.generate(8, _mistakeQuestion);
      await container
          .read(appControllerProvider.notifier)
          .completeLesson(
            LessonResult(
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              totalQuestions: mistakes.length,
              correctAnswers: 0,
              xpEarned: 10,
              mistakes: mistakes,
              completedAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LinguaQuestApp(),
        ),
      );
      await _settleBoot(tester);

      await tester.scrollUntilVisible(
        find.text('复习 2'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('复习 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('管理复习队列'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('加入错词卡'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mistake-select-review-word-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mistake-select-review-word-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mistake-select-review-word-6')),
        findsNothing,
      );
      expect(find.text('加入已选 (6)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, '加入已选 (6)'),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '加入已选 (6)'));
      await tester.pumpAndSettle();

      final customWords = container.read(appControllerProvider).customWords;
      expect(
        customWords
            .where((word) => word.word.startsWith('review-word-'))
            .length,
        6,
      );
      expect(customWords.any((word) => word.word == 'review-word-6'), false);
      expect(customWords.any((word) => word.word == 'review-word-7'), false);
    },
  );
}

Future<void> _completeNewWordCards(WidgetTester tester) async {
  for (var index = 0; index < 20; index++) {
    await tester.tap(find.widgetWithText(OutlinedButton, '认识'));
    await tester.pumpAndSettle();
    if (find.text('进入语境练习').evaluate().isNotEmpty) {
      await tester.tap(find.text('进入语境练习'));
      await tester.pumpAndSettle();
      return;
    }
    await tester.tap(find.text('下一张词卡'));
    await tester.pumpAndSettle();
  }
  fail('Could not reach the quiz entry from new word cards.');
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

class _FailingAuth implements AuthRepository {
  @override
  Future<UserProfile?> loadSession() async => null;

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw Exception('login failed');
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw Exception('register failed');
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;

  @override
  Future<void> logout() async {}
}

class _PrefsAuthRepository implements AuthRepository {
  static const _profileKey = 'linguaquest.profile';
  static const _registeredEmailsKey = 'linguaquest.test.registered_emails';
  UserProfile? _profile;

  @override
  Future<UserProfile?> loadSession() async {
    if (_profile != null) return _profile;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      _profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove(_profileKey);
      return null;
    }
    return _profile;
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final registeredEmails =
        prefs.getStringList(_registeredEmailsKey) ?? const <String>[];
    final normalizedRegisteredEmails = registeredEmails
        .map((email) => email.trim().toLowerCase())
        .toSet();
    if (normalizedRegisteredEmails.contains(normalizedEmail)) {
      throw StateError('email already registered');
    }
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'user-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    await prefs.setStringList(_registeredEmailsKey, [
      ...normalizedRegisteredEmails,
      normalizedEmail,
    ]);
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final existing = await loadSession();
    if (existing != null && existing.email == email.trim().toLowerCase()) {
      return existing;
    }
    final profile = UserProfile.demo().copyWith(
      email: email.trim().toLowerCase(),
      updatedAt: DateTime.now(),
    );
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    return profile;
  }

  @override
  Future<void> logout() async {
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}

class _MemoryCustomWordRepository implements CustomWordRepository {
  final List<CustomWord> _words = [];

  @override
  Future<List<CustomWord>> list(String uid) async {
    if (_words.where((word) => word.uid == uid).isEmpty) {
      _seed(uid);
    }
    final scoped = _words.where((word) => word.uid == uid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return scoped;
  }

  @override
  Future<CustomWord> create(CustomWord word) async {
    _words.add(word);
    return word;
  }

  @override
  Future<void> delete(String uid, String id) async {
    _words.removeWhere((word) => word.uid == uid && word.id == id);
  }

  @override
  Future<CustomWord> update(CustomWord word) async {
    final index = _words.indexWhere(
      (item) => item.uid == word.uid && item.id == word.id,
    );
    if (index == -1) {
      _words.add(word);
    } else {
      _words[index] = word;
    }
    return word;
  }

  void _seed(String uid) {
    final now = DateTime.now();
    _words.addAll([
      CustomWord.create(
        id: 'seed-1',
        uid: uid,
        word: 'resilient',
        meaning: '有韧性的',
        exampleSentence: 'A resilient learner keeps practicing after mistakes.',
        note: 'Useful for essays and interviews.',
        tag: 'character',
        difficulty: 'Medium',
        now: now.subtract(const Duration(days: 1)),
      ).copyWith(masteryLevel: 2, correctCount: 3, wrongCount: 1),
      CustomWord.create(
        id: 'seed-2',
        uid: uid,
        word: 'ambiguous',
        meaning: '含糊的',
        exampleSentence:
            'The instruction was ambiguous, so I asked for an example.',
        note: 'Often appears in reading passages.',
        tag: 'academic',
        difficulty: 'Hard',
        now: now.subtract(const Duration(days: 2)),
      ).copyWith(
        masteryLevel: 1,
        correctCount: 1,
        wrongCount: 3,
        nextReviewAt: now,
      ),
    ]);
  }
}

class _MemoryReviewRepository implements ReviewRepository {
  final List<ReviewEvent> _events = [];

  @override
  Future<void> recordReviewEvent(ReviewEvent event) async {
    _events.add(event);
  }
}

class _MemoryAppServicesRepository implements AppServicesRepository {
  final List<ForumPost> _forumPosts = [];
  final Map<String, List<ForumComment>> _forumComments = {};
  final List<ClassGroup> _classes = [];

  @override
  Future<List<RewardTask>> listRewardTasks() async {
    final profile = await _loadProfile();
    final checkedInToday = DateUtils.isSameDay(
      profile.lastStudyDate?.toLocal(),
      DateTime.now(),
    );
    final claimed = await _claimedRewardIds();
    return [
      _rewardTask(
        id: 'daily-checkin',
        title: '每日签到',
        condition: '当天完成一次学习或复习动作',
        points: 5,
        available: checkedInToday,
        claimed: claimed.contains('daily-checkin'),
      ),
      _rewardTask(
        id: 'complete-new',
        title: '完成新学',
        condition: '完成任意正式学习 Session',
        points: 12,
        available: false,
        claimed: claimed.contains('complete-new'),
      ),
      _rewardTask(
        id: 'complete-review',
        title: '完成复习',
        condition: '完成任意复习题',
        points: 10,
        available: false,
        claimed: claimed.contains('complete-review'),
      ),
      _rewardTask(
        id: 'training-challenge',
        title: '训练场挑战',
        condition: '完成任意训练场游戏',
        points: 10,
        available: false,
        claimed: claimed.contains('training-challenge'),
      ),
      _rewardTask(
        id: 'mistake-cleanup',
        title: '错词清理',
        condition: '今日错词再次答对',
        points: 8,
        available: false,
        claimed: claimed.contains('mistake-cleanup'),
      ),
      _rewardTask(
        id: 'forum-interaction',
        title: '论坛互动',
        condition: '发帖或评论通过审核',
        points: 3,
        available:
            _forumPosts.isNotEmpty ||
            _forumComments.values.any((items) => items.isNotEmpty),
        claimed: claimed.contains('forum-interaction'),
      ),
    ];
  }

  @override
  Future<RewardClaimResult> claimReward(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await _loadProfile();
    final points = switch (taskId) {
      'daily-checkin' => 5,
      'complete-new' => 12,
      'complete-review' => 10,
      'training-challenge' => 10,
      'mistake-cleanup' => 8,
      'forum-interaction' => 3,
      _ => 5,
    };
    final updated = profile.copyWith(
      xp: profile.xp + points,
      points: profile.points + points,
      updatedAt: DateTime.now(),
    );
    await prefs.setString('linguaquest.profile', jsonEncode(updated.toJson()));
    final claimed = await _claimedRewardIds();
    await prefs.setStringList('test.claimedRewards', [...claimed, taskId]);
    return RewardClaimResult(user: updated, tasks: await listRewardTasks());
  }

  @override
  Future<List<LeaderboardEntry>> listLeaderboard() async {
    final profile = await _loadProfile();
    return [
      LeaderboardEntry(
        uid: profile.uid,
        name: profile.name,
        points: profile.points,
        xp: profile.xp,
        streak: profile.streak,
        totalStudyDays: profile.totalStudyDays,
      ),
    ];
  }

  @override
  Future<AnalyticsSummary> loadAnalyticsSummary() async {
    final profile = await _loadProfile();
    return AnalyticsSummary(
      sessions: profile.totalStudyDays,
      totalQuestions: 20,
      correctAnswers: 16,
      accuracy: 0.8,
      studyMinutes: profile.totalStudyMinutes,
      earnedPoints: profile.points,
      weakWords: 2,
      forumPosts: 0,
      streakDays: profile.streak,
      totalStudyDays: profile.totalStudyDays,
      totalStudyMinutes: profile.totalStudyMinutes,
      points: profile.points,
      xp: profile.xp,
    );
  }

  @override
  Future<List<Achievement>> listAchievements() async {
    final profile = await _loadProfile();
    return [
      Achievement(
        id: 'first-session',
        title: '启航学习者',
        description: '完成第 1 次学习 Session',
        unlocked: profile.totalStudyDays > 0 || profile.xp > 0,
      ),
      Achievement(
        id: 'seven-day',
        title: '七日旅人',
        description: '累计学习 7 天',
        unlocked: profile.totalStudyDays >= 7,
      ),
      Achievement(
        id: 'point-100',
        title: '积分新星',
        description: '累计获得 100 积分',
        unlocked: profile.points >= 100 || profile.xp >= 100,
      ),
      Achievement(
        id: 'community-voice',
        title: '社区发声',
        description: '发布第 1 篇帖子',
        unlocked: _forumPosts.isNotEmpty,
      ),
    ];
  }

  @override
  Future<List<ClassGroup>> listClasses() async => [..._classes];

  @override
  Future<ClassGroup> joinClass(String code) async {
    final normalized = code.trim().toUpperCase();
    final existing = _classes
        .where((item) => item.code == normalized)
        .cast<ClassGroup?>()
        .firstOrNull;
    if (existing != null) return existing;
    final now = DateTime.now();
    final group = ClassGroup(
      id: 'class-$normalized',
      code: normalized,
      name: '$normalized 学习班',
      description: '测试班级',
      teacherName: 'LinguaQuest',
      role: 'student',
      memberCount: 1,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    _classes.add(group);
    return group;
  }

  @override
  Future<ClassProgressSummary> loadClassProgress({String? classId}) async {
    final group = _classes.isEmpty
        ? await joinClass('LQ-2048')
        : _classes.firstWhere(
            (item) => classId == null || classId.isEmpty || item.id == classId,
            orElse: () => _classes.first,
          );
    final profile = await _loadProfile();
    return ClassProgressSummary(
      classGroup: group,
      memberCount: 1,
      totalQuestions: 20,
      correctAnswers: 16,
      accuracy: 0.8,
      members: [
        ClassMemberProgress(
          uid: profile.uid,
          name: profile.name,
          role: 'student',
          points: profile.points,
          xp: profile.xp,
          streak: profile.streak,
          totalStudyDays: profile.totalStudyDays,
          totalStudyMinutes: profile.totalStudyMinutes,
          sessions: 2,
          totalQuestions: 20,
          correctAnswers: 16,
          accuracy: 0.8,
          earnedPoints: profile.points,
          joinedAt: group.joinedAt,
        ),
      ],
      lessons: const [
        ClassLessonProgress(
          lessonId: 'beginner-lesson-1',
          sessions: 2,
          totalQuestions: 20,
          correctAnswers: 16,
          accuracy: 0.8,
        ),
      ],
      weakWords: const [ClassWeakWord(wordId: 'seed-2', mistakeCount: 2)],
    );
  }

  @override
  Future<LotteryDrawResult> drawLottery() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await _loadProfile();
    final updated = profile.copyWith(
      points: (profile.points - 20).clamp(0, 999999).toInt(),
      xp: (profile.xp - 20).clamp(0, 999999).toInt(),
      updatedAt: DateTime.now(),
    );
    await prefs.setString('linguaquest.profile', jsonEncode(updated.toJson()));
    return LotteryDrawResult(
      draw: LotteryDraw(
        id: 'test-draw',
        prize: '学习徽章',
        pointsCost: 20,
        drawnAt: DateTime.now(),
      ),
      user: updated,
    );
  }

  @override
  Future<List<ForumPost>> listForumPosts() async {
    if (_forumPosts.isNotEmpty) return [..._forumPosts];
    final now = DateTime.now();
    final seeded = ForumPost(
      id: 'test-post-1',
      authorId: 'test-user',
      authorName: '学习者',
      title: '今日打卡：复习完成',
      content: '错词集中在近义辨析，明天继续从训练场开始。',
      tags: const ['今日打卡'],
      likeCount: 3,
      commentCount: 1,
      status: 'published',
      createdAt: now,
    );
    _forumPosts.add(seeded);
    _forumComments[seeded.id] = [
      ForumComment(
        id: 'test-comment-1',
        postId: seeded.id,
        authorId: 'test-user',
        authorName: '学习者',
        content: '继续保持复习节奏。',
        status: 'published',
        createdAt: now,
      ),
    ];
    return [..._forumPosts];
  }

  @override
  Future<ForumPostDetail> loadForumPost(String id) async {
    await listForumPosts();
    final post = _forumPosts.firstWhere((item) => item.id == id);
    return ForumPostDetail(
      post: post,
      comments: [...(_forumComments[id] ?? const <ForumComment>[])],
    );
  }

  @override
  Future<ForumPost> createForumPost({
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    final profile = await _loadProfile();
    final post = ForumPost(
      id: 'test-post-${_forumPosts.length + 1}',
      authorId: profile.uid,
      authorName: profile.name,
      title: title,
      content: content,
      tags: tags,
      likeCount: 0,
      commentCount: 0,
      status: 'published',
      createdAt: DateTime.now(),
    );
    _forumPosts.insert(0, post);
    return post;
  }

  @override
  Future<ForumComment> addForumComment({
    required String postId,
    required String content,
  }) async {
    final profile = await _loadProfile();
    final comment = ForumComment(
      id: 'test-comment-${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      authorId: profile.uid,
      authorName: profile.name,
      content: content,
      status: 'published',
      createdAt: DateTime.now(),
    );
    (_forumComments[postId] ??= []).add(comment);
    for (var index = 0; index < _forumPosts.length; index++) {
      final post = _forumPosts[index];
      if (post.id == postId) {
        _forumPosts[index] = ForumPost(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatarUrl: post.authorAvatarUrl,
          title: post.title,
          content: post.content,
          imageUrls: post.imageUrls,
          tags: post.tags,
          likeCount: post.likeCount,
          commentCount: post.commentCount + 1,
          status: post.status,
          createdAt: post.createdAt,
        );
      }
    }
    return comment;
  }

  @override
  Future<ForumPost> likeForumPost(String id) async {
    await listForumPosts();
    for (var index = 0; index < _forumPosts.length; index++) {
      final post = _forumPosts[index];
      if (post.id == id) {
        final liked = ForumPost(
          id: post.id,
          authorId: post.authorId,
          authorName: post.authorName,
          authorAvatarUrl: post.authorAvatarUrl,
          title: post.title,
          content: post.content,
          imageUrls: post.imageUrls,
          tags: post.tags,
          likeCount: post.likeCount + 1,
          commentCount: post.commentCount,
          status: post.status,
          createdAt: post.createdAt,
        );
        _forumPosts[index] = liked;
        return liked;
      }
    }
    throw StateError('post not found');
  }

  @override
  Future<List<AppNotification>> listNotifications() async {
    return [
      AppNotification(
        id: 'test-notification',
        type: 'reward',
        title: '抽奖结果',
        body: '你抽中了学习徽章。',
        targetRoute: '/discover',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<List<AiConversation>> listAiConversations() async {
    final now = DateTime.now();
    return [
      AiConversation(
        id: 'test-ai',
        feature: 'qa',
        title: '知识问答 · affect',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<AiConversationDetail> loadAiConversation(String id) async {
    final now = DateTime.now();
    return AiConversationDetail(
      conversation: AiConversation(
        id: id,
        feature: 'qa',
        title: '知识问答 · affect',
        createdAt: now,
        updatedAt: now,
      ),
      messages: [
        AiMessage(
          id: 'test-ai-user',
          conversationId: id,
          role: 'user',
          content: '解释 affect 和 effect 的区别',
          payload: const {},
          createdAt: now,
        ),
        AiMessage(
          id: 'test-ai-assistant',
          conversationId: id,
          role: 'assistant',
          content: '测试解释：affect 是动词，effect 常作名词。',
          payload: const {
            'sections': [
              {'title': '词性', 'body': 'affect 常作动词；effect 常作名词。'},
            ],
          },
          createdAt: now,
        ),
      ],
    );
  }

  @override
  Future<void> deleteAiConversation(String id) async {}

  @override
  Future<AiCompletionResult> completeAi({
    required String feature,
    required String prompt,
    String? conversationId,
  }) async {
    return AiCompletionResult(
      conversationId: conversationId ?? 'test-ai',
      feature: feature,
      title: 'AI 学习',
      response: '测试解释：$prompt',
      payload: {
        'points': ['测试解释'],
      },
    );
  }

  Future<UserProfile> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('linguaquest.profile');
    return raw == null
        ? UserProfile.demo()
        : UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<Set<String>> _claimedRewardIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('test.claimedRewards')?.toSet() ?? <String>{};
  }

  RewardTask _rewardTask({
    required String id,
    required String title,
    required String condition,
    required int points,
    required bool available,
    required bool claimed,
  }) {
    return RewardTask(
      id: id,
      title: title,
      taskType: 'test',
      condition: condition,
      points: points,
      isAvailable: available,
      isClaimed: claimed,
      claimedAt: claimed ? DateTime.now() : null,
    );
  }
}

class _StaticLearningRepository implements LearningRepository {
  const _StaticLearningRepository(this.lessons);

  final List<Lesson> lessons;

  @override
  Future<List<WordBook>> listWordBooks() async => const [];

  @override
  Future<List<Lesson>> listLessons() async => lessons;

  @override
  Future<Map<String, dynamic>?> loadStudyPlan(String uid) async => null;

  @override
  Future<Map<String, dynamic>?> saveStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async => data;

  @override
  Future<void> clearStudyPlan(String uid) async {}

  @override
  Future<List<TargetWordProgress>> listTargetWordProgress(String uid) async =>
      const [];

  @override
  Future<ActivitySummary> loadActivitySummary(String uid) async =>
      ActivitySummary.empty;

  @override
  Future<UserProfile> recordStudySession(StudySession session) async {
    return UserProfile.demo().copyWith(
      uid: session.uid,
      xp: session.xpEarned,
      points: session.xpEarned,
      lastStudyDate: session.endedAt,
      updatedAt: session.endedAt,
    );
  }

  @override
  Future<void> upsertTargetWordProgress(
    String uid,
    TargetWordProgress progress,
  ) async {}
}

class _FileLearningRepository implements LearningRepository {
  List<WordBook>? _wordBooks;
  final Map<String, Map<String, TargetWordProgress>> _targetProgress = {};
  final Map<String, Map<String, dynamic>> _studyPlans = {};
  final List<StudySession> _sessions = [];

  @override
  Future<List<WordBook>> listWordBooks() async {
    final cached = _wordBooks;
    if (cached != null) return cached;
    final candidates = [
      File('../server/data/wordbooks_p0.json'),
      File('server/data/wordbooks_p0.json'),
    ];
    final file = candidates.firstWhere((item) => item.existsSync());
    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    return _wordBooks = decoded
        .cast<Map<String, dynamic>>()
        .map(WordBook.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Lesson>> listLessons() async {
    final books = await listWordBooks();
    if (books.isEmpty) return const [];
    return lessonsFromWordBook(books.first);
  }

  @override
  Future<Map<String, dynamic>?> loadStudyPlan(String uid) async {
    return _studyPlans[uid];
  }

  @override
  Future<Map<String, dynamic>?> saveStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    return _studyPlans[uid] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> clearStudyPlan(String uid) async {
    _studyPlans.remove(uid);
  }

  @override
  Future<List<TargetWordProgress>> listTargetWordProgress(String uid) async {
    return (_targetProgress[uid] ?? const <String, TargetWordProgress>{}).values
        .toList(growable: false);
  }

  @override
  Future<void> upsertTargetWordProgress(
    String uid,
    TargetWordProgress progress,
  ) async {
    (_targetProgress[uid] ??= {})[progress.wordId] = progress;
  }

  @override
  Future<ActivitySummary> loadActivitySummary(String uid) async {
    final today = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final persistedReviewIds =
        prefs.getString('linguaquest.today.date') == todayKey
        ? prefs.getStringList('linguaquest.today.reviews') ?? const <String>[]
        : const <String>[];
    final persistedLessonIds =
        prefs.getString('linguaquest.today.date') == todayKey
        ? prefs.getStringList('linguaquest.today.lessons') ?? const <String>[]
        : const <String>[];
    final persistedCompletedIds =
        prefs.getStringList('linguaquest.completedLessons') ?? const <String>[];
    return ActivitySummary(
      completedLessonIds: {
        ...persistedCompletedIds,
        for (final session in _sessions)
          if (session.uid == uid) session.lessonId,
      },
      todayCompletedLessonIds: {
        ...persistedLessonIds,
        for (final session in _sessions)
          if (session.uid == uid &&
              DateUtils.isSameDay(session.endedAt.toLocal(), today))
            session.lessonId,
      },
      todayReviewWordIds: persistedReviewIds.toSet(),
    );
  }

  @override
  Future<UserProfile> recordStudySession(StudySession session) async {
    _sessions.add(session);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('linguaquest.profile');
    final profile = raw == null
        ? UserProfile.demo().copyWith(uid: session.uid)
        : UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final updated = profile.copyWith(
      xp: profile.xp + session.xpEarned,
      points: profile.points + session.xpEarned,
      lastStudyDate: session.endedAt,
      updatedAt: session.endedAt,
    );
    await prefs.setString('linguaquest.profile', jsonEncode(updated.toJson()));
    return updated;
  }
}

class _FlakyLearningRepository implements LearningRepository {
  int listAttempts = 0;

  @override
  Future<List<WordBook>> listWordBooks() async => const [];

  @override
  Future<List<Lesson>> listLessons() async {
    listAttempts++;
    if (listAttempts == 1) {
      throw Exception('temporary catalog failure');
    }
    return seedLessons();
  }

  @override
  Future<Map<String, dynamic>?> loadStudyPlan(String uid) async => null;

  @override
  Future<Map<String, dynamic>?> saveStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async => data;

  @override
  Future<void> clearStudyPlan(String uid) async {}

  @override
  Future<List<TargetWordProgress>> listTargetWordProgress(String uid) async =>
      const [];

  @override
  Future<ActivitySummary> loadActivitySummary(String uid) async =>
      ActivitySummary.empty;

  @override
  Future<UserProfile> recordStudySession(StudySession session) async {
    return UserProfile.demo().copyWith(
      uid: session.uid,
      xp: session.xpEarned,
      points: session.xpEarned,
      lastStudyDate: session.endedAt,
      updatedAt: session.endedAt,
    );
  }

  @override
  Future<void> upsertTargetWordProgress(
    String uid,
    TargetWordProgress progress,
  ) async {}
}

class _ConcurrentCustomWordRepository implements CustomWordRepository {
  final List<CustomWord> words = [];
  int _activeCreates = 0;
  int maxConcurrentCreates = 0;

  @override
  Future<List<CustomWord>> list(String uid) async => words;

  @override
  Future<CustomWord> create(CustomWord word) async {
    _activeCreates++;
    if (_activeCreates > maxConcurrentCreates) {
      maxConcurrentCreates = _activeCreates;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    words.add(word);
    _activeCreates--;
    return word;
  }

  @override
  Future<void> delete(String uid, String id) async {
    words.removeWhere((word) => word.uid == uid && word.id == id);
  }

  @override
  Future<CustomWord> update(CustomWord word) async {
    final index = words.indexWhere((item) => item.id == word.id);
    if (index == -1) {
      words.add(word);
    } else {
      words[index] = word;
    }
    return word;
  }
}

QuizQuestion _mistakeQuestion(int index) {
  final word = Word(
    id: 'review-word-$index',
    word: 'review-word-$index',
    phonetic: '/word/',
    meaning: 'meaning $index',
    definition: 'Definition $index',
    partOfSpeech: 'noun',
    exampleSentence: 'This is review word $index.',
    exampleTranslation: '这是复习单词 $index。',
    imageCue: '📘',
    difficulty: 'Medium',
    tags: const ['review'],
  );
  return QuizQuestion(
    id: 'review-question-$index',
    type: QuizQuestionType.meaningChoice,
    prompt: 'Choose the meaning',
    answer: word.meaning,
    options: [word.meaning, 'wrong'],
    explanation: 'Explanation $index',
    word: word,
  );
}

String _todayDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
