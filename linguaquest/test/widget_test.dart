import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/widgets/learning_badges.dart';
import 'package:linguaquest/core/widgets/pronunciation_controls.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/lesson_result.dart';
import 'package:linguaquest/data/models/study_session.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/repositories/custom_word_repository.dart';
import 'package:linguaquest/data/repositories/learning_repository.dart';
import 'package:linguaquest/data/seed/seed_lessons.dart';
import 'package:linguaquest/features/auth/goal_setup_screen.dart';
import 'package:linguaquest/features/learning/lesson_preview_screen.dart';
import 'package:linguaquest/features/quiz/lesson_result_screen.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
import 'package:linguaquest/features/search/search_screen.dart';
import 'package:linguaquest/features/wordbook/target_word_detail_screen.dart';
import 'package:linguaquest/features/wordbook/word_detail_screen.dart';
import 'package:linguaquest/features/wordbook/wordbook_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts at onboarding when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('LinguaQuest'), findsWidgets);
    expect(find.byIcon(Icons.route_outlined), findsWidgets);

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
      'linguaquest.today.lessons': ['lesson-exam-1'],
      'linguaquest.today.reviews': ['seed-1'],
    });

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.text('今日词条'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日词条'));
    await tester.pumpAndSettle();

    expect(find.text('allocate'), findsWidgets);
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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final campusLesson = container
          .read(appControllerProvider)
          .lessons
          .singleWhere((lesson) => lesson.id == 'lesson-campus-1');
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
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('发现'));
      await tester.pumpAndSettle();

      final newLearningTask = find.ancestor(
        of: find.text('完成新学'),
        matching: find.byType(InkWell),
      );
      expect(newLearningTask, findsOneWidget);
      expect(
        find.descendant(of: newLearningTask, matching: find.text('去完成 +20 XP')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: newLearningTask, matching: find.text('领取 +20 XP')),
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
      ProviderScope(
        overrides: [
          customWordRepositoryProvider.overrideWithValue(customWordRepository),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
      find.descendant(of: cleanupTask, matching: find.text('去完成 +10 XP')),
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
      ProviderScope(
        overrides: [
          customWordRepositoryProvider.overrideWithValue(customWordRepository),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
      find.descendant(of: cleanupTask, matching: find.text('去完成 +10 XP')),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(_FailingAuth())],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(learningRepository),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(learningRepository.listAttempts, 1);
    expect(find.textContaining('LinguaQuest 启动失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GoalSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dailyEnglish = find.byKey(const ValueKey('choice-Daily English'));
    final businessEnglish = find.byKey(
      const ValueKey('choice-Business English'),
    );

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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
    expect(find.text('雅思核心词汇 · 已学 0/3 词'), findsOneWidget);
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

  test('seed learning path contains blueprint-sized lesson range', () {
    final lessons = seedLessons();
    final firstLessonTypes = {
      for (final question in lessons.first.questions) question.type,
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
    final container = ProviderContainer();
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
    expect(find.text('appetite'), findsWidgets);
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LessonPreviewScreen(lessonId: 'lesson-campus-1'),
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const QuizSessionScreen(lessonId: 'lesson-campus-1'),
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
          home: const QuizSessionScreen(
            lessonId: 'lesson-campus-1',
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
      final lesson = seedLessons().last;
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
        ProviderScope(
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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.tap(find.text('评估'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再试一次'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分配'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('evaluate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('对比'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'contrast');
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(find.text('答对 3/4 题 · 已入账 +23 XP · 错题已进入复习。'), findsOneWidget);
    expect(find.text('已入账 +23 XP'), findsOneWidget);
    expect(find.text('刚刚到账 +23 XP'), findsOneWidget);
    expect(find.text('总积分 23 XP'), findsOneWidget);
    expect(find.text('当前总积分 23 XP。XP 会同步到个人主页、排行榜和发现页抽奖余额。'), findsOneWidget);
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
    expect(find.text('allocate'), findsWidgets);
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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
    await tester.tap(find.text('分配'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pump();

    Finder continueButton() => find.widgetWithText(FilledButton, '继续');

    expect(find.textContaining('答对了'), findsOneWidget);
    expect(find.textContaining('强化记忆：allocate · 分配'), findsOneWidget);
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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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

    await tester.tap(find.text('评估'));
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
      find.ancestor(of: find.text('评估'), matching: find.byType(OutlinedButton)),
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

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
    final container = ProviderContainer();
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

  test('mock register rejects duplicate email', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
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
    final container = ProviderContainer();
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
    final completedLessonId = seedLessons().first.id;
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
      'linguaquest.completedLessons': [completedLessonId],
    });
    final container = ProviderContainer();
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
    final container = ProviderContainer();
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
    final container = ProviderContainer();
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
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(
            _StaticLearningRepository([emptyLesson, taglessLesson]),
          ),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
    final container = ProviderContainer();
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
    final container = ProviderContainer();
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
    final container = ProviderContainer();
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

  testWidgets('mixed study keeps wrong new words in the same learning round', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customWordRepositoryProvider.overrideWithValue(
            _EmptyCustomWordRepository(),
          ),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.text('新学 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '新学 10'));
    await tester.pumpAndSettle();

    expect(find.text('今日混排学习包'), findsOneWidget);
    expect(find.text('allocate'), findsOneWidget);

    await tester.tap(find.text('不认识'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('进入识别题'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '还不确定 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    expect(find.textContaining('allocate'), findsWidgets);

    if (find.text('再试一次').evaluate().isNotEmpty) {
      await tester.tap(find.text('再试一次'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(OutlinedButton, '分配'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(find.text('加入稍后复现'), findsOneWidget);
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
      final container = ProviderContainer();
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
    final container = ProviderContainer(
      overrides: [
        customWordRepositoryProvider.overrideWithValue(customWordRepository),
      ],
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
    final container = ProviderContainer();
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
    await tester.pumpAndSettle(const Duration(seconds: 1));

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
      final container = ProviderContainer();
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
      await tester.pumpAndSettle(const Duration(seconds: 1));

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
  for (var index = 0; index < 2; index++) {
    await tester.tap(find.widgetWithText(OutlinedButton, '认识'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一张词卡'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.widgetWithText(OutlinedButton, '认识'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('进入语境练习'));
  await tester.pumpAndSettle();
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

class _StaticLearningRepository implements LearningRepository {
  const _StaticLearningRepository(this.lessons);

  final List<Lesson> lessons;

  @override
  Future<List<Lesson>> listLessons() async => lessons;

  @override
  Future<void> recordStudySession(StudySession session) async {}
}

class _FlakyLearningRepository implements LearningRepository {
  int listAttempts = 0;

  @override
  Future<List<Lesson>> listLessons() async {
    listAttempts++;
    if (listAttempts == 1) {
      throw Exception('temporary catalog failure');
    }
    return seedLessons();
  }

  @override
  Future<void> recordStudySession(StudySession session) async {}
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

class _EmptyCustomWordRepository implements CustomWordRepository {
  @override
  Future<List<CustomWord>> list(String uid) async => const [];

  @override
  Future<CustomWord> create(CustomWord word) async => word;

  @override
  Future<void> delete(String uid, String id) async {}

  @override
  Future<CustomWord> update(CustomWord word) async => word;
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
