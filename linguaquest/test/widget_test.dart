import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/widgets/quest_card.dart';
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

    expect(find.text('Create account'), findsOneWidget);
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

    expect(find.text('Today’s learning pack'), findsOneWidget);
    expect(find.text('Ready for Campus Starter?'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Learn'), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Word of the day'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('learner@lingua.quest'), findsNothing);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'learner@lingua.quest',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.textContaining('login failed'), findsOneWidget);
    expect(find.text('Today’s learning pack'), findsNothing);
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
    expect(find.textContaining('Could not start LinguaQuest'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
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

    await tester.fling(
      find.text('Today’s learning pack'),
      const Offset(-24, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Today’s learning pack'), findsOneWidget);

    await tester.drag(
      find.text('Today’s learning pack'),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learning Path'), findsOneWidget);
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
                  QuestCard(
                    color: warmSurface,
                    child: const Text('Warm surface text'),
                  ),
                  QuestCard(
                    color: accentSurface,
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
    expect(seedLessons(), hasLength(greaterThanOrEqualTo(6)));
    expect(seedLessons(), hasLength(lessThanOrEqualTo(10)));
  });

  testWidgets('lesson mistake appears in review center after result', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'mistake-user',
      name: 'Mia',
      email: 'mia@lingua.quest',
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

    await tester.tap(find.text('Continue lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('讲座；授课'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('lecture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'deadline');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Back to learning path'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to learning path'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Travel Basics'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Travel Basics'), findsOneWidget);
    expect(find.text('Current'), findsWidgets);

    await tester.tap(find.text('Review').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('commute'), 300);
    await tester.pumpAndSettle();
    expect(find.text('commute'), findsWidgets);
    expect(find.text('Lesson'), findsWidgets);
  });

  testWidgets('lesson and quiz screens expose a working back path', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'back-user',
      name: 'Noah',
      email: 'noah@lingua.quest',
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

    await tester.tap(find.text('Continue lesson'));
    await tester.pumpAndSettle();

    expect(find.text('Start quiz'), findsWidgets);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Today’s learning pack'), findsOneWidget);

    await tester.tap(find.text('Continue lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz').first);
    await tester.pumpAndSettle();

    expect(find.text('Check'), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.text('讲座；授课'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Leave quiz?'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.text('Check'), findsOneWidget);
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    final selectedOptionButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('讲座；授课'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(selectedOptionButton.onPressed, isNotNull);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Start quiz'), findsWidgets);
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
      'This email is already registered. Try logging in instead.',
    );

    await controller.logout();
    expect(
      await controller.register('Ava', 'ava@lingua.quest', 'password123'),
      false,
    );
    expect(
      container.read(appControllerProvider).errorMessage,
      'This email is already registered. Try logging in instead.',
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

    expect(find.text('Ready for Empty Lesson?'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Open word cards'), findsOneWidget);

    await tester.tap(find.text('Wordbook').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Visual Wordbook'), findsOneWidget);
    expect(find.text('context'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
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

    await tester.tap(find.text('Review').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add Mistake Cards'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Add Selected (2)'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Add Selected (0)'), findsOneWidget);

    await container
        .read(appControllerProvider.notifier)
        .updateThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.text('Add Selected (0)'), findsOneWidget);
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

      await tester.tap(find.text('Review').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Add Mistake Cards'), 300);
      await tester.pumpAndSettle();

      expect(find.text('review-word-0'), findsOneWidget);
      expect(find.text('review-word-5'), findsOneWidget);
      expect(find.text('review-word-6'), findsNothing);
      expect(find.text('Add Selected (6)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Add Selected (6)'),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add Selected (6)'));
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
