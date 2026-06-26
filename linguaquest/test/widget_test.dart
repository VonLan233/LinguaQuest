import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/routing/app_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/utils/quiz_localization.dart';
import 'package:linguaquest/core/utils/ui_labels.dart';
import 'package:linguaquest/core/utils/wordbook_progress.dart';
import 'package:linguaquest/core/widgets/app_button.dart';
import 'package:linguaquest/core/widgets/app_card.dart';
import 'package:linguaquest/core/widgets/learning_badges.dart';
import 'package:linguaquest/core/widgets/pronunciation_controls.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/daily_reward_task.dart';
import 'package:linguaquest/data/models/exercise_record.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/lesson_result.dart';
import 'package:linguaquest/data/models/point_grant_result.dart';
import 'package:linguaquest/data/models/study_session.dart';
import 'package:linguaquest/data/models/study_plan.dart';
import 'package:linguaquest/data/models/user_word.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/dictionary_search.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/data/remote/api_client.dart';
import 'package:linguaquest/data/repositories/api_repositories.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/repositories/custom_word_repository.dart';
import 'package:linguaquest/data/repositories/learning_repository.dart';
import 'package:linguaquest/data/repositories/reward_repository.dart';
import 'package:linguaquest/data/repositories/reward_task_repository.dart';
import 'package:linguaquest/data/repositories/study_plan_repository.dart';
import 'package:linguaquest/data/seed/seed_lessons.dart';
import 'package:linguaquest/data/wordbook_asset_loader.dart';
import 'package:linguaquest/features/auth/goal_setup_screen.dart';
import 'package:linguaquest/features/learning/lesson_preview_screen.dart';
import 'package:linguaquest/features/quiz/lesson_result_screen.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
import 'package:linguaquest/features/profile/profile_screen.dart';
import 'package:linguaquest/features/profile/study_plan_settings_screen.dart';
import 'package:linguaquest/features/search/search_screen.dart';
import 'package:linguaquest/features/study/session/session_queue_builder.dart';
import 'package:linguaquest/data/models/study_session_draft.dart';
import 'package:linguaquest/features/wordbook/target_word_detail_screen.dart';
import 'package:linguaquest/features/wordbook/word_detail_screen.dart';
import 'package:linguaquest/features/wordbook/wordbook_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('default user display name localizes untouched defaults', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    final ms = await AppLocalizations.delegate.load(const Locale('ms'));
    final user = UserProfile.demo();

    expect(displayUserName(user, l10n: en), 'Explorer');
    expect(displayUserName(user, l10n: zh), '探索者');
    expect(displayUserName(user, l10n: ms), isNot('学习者'));
  });

  test('custom user display name is preserved', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final user = UserProfile.demo().copyWith(name: 'Ava');

    expect(displayUserName(user, l10n: en), 'Ava');
  });

  testWidgets('starts at onboarding when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('LinguaQuest'), findsWidgets);
    expect(find.byIcon(AppIcons.route), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
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

    expect(find.text('6 days check-in'), findsOneWidget);
    expect(find.text('HSK 1 · Intermediate'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Training'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Word of the Day'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Word of the Day'), findsOneWidget);

    // Cozy Quest cards landed on home.
    expect(find.byType(AppCard), findsWidgets);
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
      'linguaquest.today.lessons': ['hsk1-lesson-1'],
      'linguaquest.today.reviews': ['seed-1'],
    });

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The label and the count now stack on two lines (was one combined string).
    expect(find.text('Today completed'), findsOneWidget);
    expect(find.text('4/14 words'), findsOneWidget);
    expect(find.text('29%'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

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

    await tester.tap(find.text('Search words, phrases, or examples'));
    await tester.pumpAndSettle();

    expect(find.text('HSK 1'), findsOneWidget);
    expect(find.text('Enter a keyword to start searching'), findsOneWidget);
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
      find.text('Word of the Day'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Word of the Day'));
    await tester.pumpAndSettle();

    expect(find.text('爱'), findsWidgets);
    expect(find.text('Add to custom words'), findsOneWidget);
    expect(find.text('In current plan'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('AI Learning'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('AI Learning'), findsOneWidget);
    expect(find.text('Collocations'), findsOneWidget);
    expect(find.text('Synonyms / Antonyms'), findsOneWidget);
  });

  test('word initial cue falls back for empty custom words', () {
    expect(wordInitialCue(''), '?');
    expect(wordInitialCue('  '), '?');
    expect(wordInitialCue('apple'), '📖');
  });

  test('profile new wordbook count uses custom copies only', () {
    final now = DateTime(2026, 5, 25);
    final target = seedLessons().first.words.first;
    final customCopy = CustomWord.create(
      id: 'custom-${target.id}',
      uid: 'u1',
      word: target.word,
      meaning: target.meaning,
      exampleSentence: target.exampleSentence,
      now: now,
    );
    final targetProgress = UserWord.create(
      uid: 'u1',
      word: target,
      wordBookId: 'IELTS',
      now: now,
    ).copyWith(isInNewWordbook: true);
    final state = AppState.initial().copyWith(
      customWords: [customCopy],
      userWords: [targetProgress],
    );

    expect(newWordbookCount(state), 1);
  });

  test('wordbook progress counts learned user words by status', () {
    final now = DateTime(2026, 5, 25);
    final words = seedLessons().expand((lesson) => lesson.words).toList();
    final learned = UserWord.create(
      uid: 'u1',
      word: words[0],
      wordBookId: 'hsk1',
      now: now,
    ).copyWith(status: 'Learning');
    final newWord = UserWord.create(
      uid: 'u1',
      word: words[1],
      wordBookId: 'hsk1',
      now: now,
    );
    final ignored = UserWord.create(
      uid: 'u1',
      word: words[2],
      wordBookId: 'hsk1',
      now: now,
    ).copyWith(status: 'Mastered', isIgnored: true);
    // The runtime collapses every book id to the single HSK book, so a word with
    // any book id but a learned status still counts toward the current book.
    final reviewed = UserWord.create(
      uid: 'u1',
      word: words[3],
      wordBookId: 'GRE',
      now: now,
    ).copyWith(status: 'Review');

    // Learned (Learning) + reviewed (Review) count; New and ignored/Mastered are
    // excluded. So two of the four user words are learned for the current book.
    expect(
      learnedWordCountForBook(
        userWords: [learned, newWord, ignored, reviewed],
        wordBookId: 'hsk1',
        wordIds: words.take(3).map((word) => word.id).toSet(),
      ),
      2,
    );
  });

  test('localized quiz question resolves baked Chinese answer options', () {
    final lessons = seedLessons();
    final lesson = lessons.first;
    final question = lesson.questions.first;
    final localized = localizeQuizQuestion(
      question,
      lessons.expand((lesson) => lesson.words),
      'en',
    );
    final chineseText = RegExp(r'[\u4e00-\u9fff]');

    expect(localized.answer, question.word.primaryDefinitionFor('en'));
    expect(localized.answer, isNot(contains(chineseText)));
    expect(localized.options, isNot(contains(question.word.meaning)));
    for (final option in localized.options) {
      expect(option, isNot(contains(chineseText)));
    }
  });

  test('study session draft round trips queue and progress', () {
    final now = DateTime(2026, 5, 25);
    final word = seedLessons().first.words.first;
    final item = StudySessionQueueItem(
      id: 'new-${word.id}-understanding-0',
      wordId: word.id,
      source: StudySessionItemSource.newWord,
      step: StudySessionStep.understanding,
      lessonWord: word,
      attempt: 0,
      affectsSchedule: false,
    );
    final log = StudyAnswerLog(
      itemId: item.id,
      wordId: item.wordId,
      source: item.source,
      step: item.step,
      isCorrect: true,
      responseTimeMs: 1200,
      confidence: 4,
      selectedAnswer: word.meaning,
      answeredAt: now,
    );
    final draft = StudySessionDraft(
      uid: 'u1',
      mode: StudySessionEntryMode.mixed,
      lessonId: 'lesson-1',
      startedAt: now,
      savedAt: now.add(const Duration(minutes: 3)),
      completedItems: 2,
      correctAnswers: 1,
      confidence: 4,
      reviewTargetRatio: 0.3,
      newTargetRatio: 0.7,
      dueReviewCount: 1,
      newWordCount: 3,
      weakWordCount: 0,
      queue: [item],
      answerLogs: [log],
      wrongItemIds: {'w2'},
      scheduledWrongIds: {'w2:0'},
    );

    final restored = StudySessionDraft.fromJson(draft.toJson());

    expect(restored.uid, 'u1');
    expect(restored.mode, StudySessionEntryMode.mixed);
    expect(restored.lessonId, 'lesson-1');
    expect(restored.completedItems, 2);
    expect(restored.correctAnswers, 1);
    expect(restored.queue.single.wordId, word.id);
    expect(restored.queue.single.lessonWord?.word, word.word);
    expect(restored.answerLogs.single.responseTimeMs, 1200);
    expect(restored.wrongItemIds, contains('w2'));
  });

  testWidgets('mixed study clears a saved draft from another lesson', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'stale-draft-user',
      name: 'Stale',
      email: 'stale@lingua.quest',
      targetExam: 'IELTS',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    final word = seedLessons().first.words.first;
    final staleDraft = StudySessionDraft(
      uid: profile.uid,
      mode: StudySessionEntryMode.mixed,
      lessonId: 'old-lesson',
      startedAt: now,
      savedAt: now,
      completedItems: 2,
      correctAnswers: 1,
      confidence: 4,
      reviewTargetRatio: 0.3,
      newTargetRatio: 0.7,
      dueReviewCount: 0,
      newWordCount: 1,
      weakWordCount: 0,
      queue: [
        StudySessionQueueItem(
          id: 'new-${word.id}-understanding-0',
          wordId: word.id,
          source: StudySessionItemSource.newWord,
          step: StudySessionStep.understanding,
          lessonWord: word,
          attempt: 0,
          affectsSchedule: false,
        ),
      ],
      answerLogs: const [],
      wrongItemIds: const {},
      scheduledWrongIds: const {},
    );
    const key = 'linguaquest.study_session_draft.stale-draft-user.mixed';
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
      key: jsonEncode(staleDraft.toJson()),
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

    await tester.tap(find.textContaining('Start'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(key), isNull);
    expect(find.text("Today's mixed pack"), findsOneWidget);
  });

  testWidgets('pronunciation controls expose loading and retry states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PronunciationControls(word: '')),
      ),
    );

    expect(find.text('英音'), findsOneWidget);
    expect(find.text('美音'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pronunciation-uk')));
    await tester.pumpAndSettle();

    // SnackBars are gone; failure now shows as inline retry indicator.
    expect(find.text('英音发音失败，请重试'), findsOneWidget);
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
      find.textContaining('Start'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Start'));
    await tester.pumpAndSettle();

    expect(find.text("Today's mixed pack"), findsOneWidget);
    expect(find.text('今日新词包'), findsNothing);
    expect(find.text('进入词卡学习'), findsNothing);
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

    final reviewButton = find.widgetWithText(AppSecondaryButton, 'Review');
    await tester.scrollUntilVisible(
      reviewButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Quick review'), findsOneWidget);
    // The first due review word (谢谢) is presented as a recognition question:
    // its English meaning option is on screen.
    expect(find.textContaining('thank you; thanks'), findsWidgets);
    // Instant judgment: question steps no longer carry a check button.
    expect(find.text('Check'), findsNothing);
    expect(find.text('Manage review queue'), findsOneWidget);
    // Cozy Quest cards landed on the mixed study session screen.
    expect(find.byType(AppCard), findsWidgets);
    expect(find.text('记住了'), findsNothing);
    expect(find.text('没记住'), findsNothing);
    expect(find.text('显示释义'), findsNothing);
    expect(find.text('Add mistake cards'), findsNothing);

    // A review item is recorded on the first attempt: a wrong tap shows the
    // feedback, then auto-advances after the 1500ms timer (no retry).
    await _tapAnyOptionExceptNoSettle(tester, 'thank you; thanks');
    await tester.pump();
    expect(find.textContaining('Wrong'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // The recall card for the reviewed word (谢谢) appears.
    expect(find.text('Add to later recall'), findsOneWidget);
    expect(find.textContaining('谢谢'), findsWidgets);

    await tester.tap(find.text('Add to later recall'));
    await tester.pumpAndSettle();

    // Advanced to the next due word (你好) recognition question.
    expect(find.textContaining('hello; hi'), findsWidgets);

    // Drain the top-notice auto-dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
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

    final reviewButton = find.widgetWithText(AppSecondaryButton, 'Review');
    await tester.scrollUntilVisible(
      reviewButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    // Instant judgment records the attempt on tap (no check button); the wrong
    // review answer would auto-advance after 1500ms, but we leave before then.
    await _tapAnyOptionExceptNoSettle(tester, 'thank you; thanks');
    await tester.pump();

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Save this progress?'), findsOneWidget);
    expect(
      find.textContaining('unfinished words return to the pack next time'),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep studying'));
    await tester.pumpAndSettle();

    expect(find.text('Quick review'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave without saving'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Task Console'), findsOneWidget);
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

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Point Tasks'));
    await tester.pumpAndSettle();

    expect(find.byType(AppCard), findsWidgets);
    expect(find.text('Daily Check-in'), findsOneWidget);
    expect(find.text('Go +5 XP'), findsOneWidget);
    expect(find.textContaining('Earned'), findsNothing);
  });

  test(
    'lesson completion compares server UTC last study date locally',
    () async {
      final now = DateTime.now();
      final yesterdayEarlyLocal = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1)).add(const Duration(minutes: 30));
      final serverLastStudyDate = yesterdayEarlyLocal.toUtc();
      final profile = UserProfile(
        uid: 'utc-streak-user',
        name: 'Uma',
        email: 'uma@lingua.quest',
        targetExam: 'IELTS',
        level: 'Intermediate',
        dailyGoal: 12,
        xp: 120,
        streak: 4,
        lastStudyDate: serverLastStudyDate,
        createdAt: serverLastStudyDate,
        updatedAt: serverLastStudyDate,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final lesson = container
          .read(appControllerProvider)
          .lessons
          .firstWhere((lesson) => !lesson.isTrainingPack);

      expect(
        await container
            .read(appControllerProvider.notifier)
            .completeLesson(
              LessonResult(
                lessonId: lesson.id,
                lessonTitle: lesson.title,
                totalQuestions: lesson.questions.length,
                correctAnswers: lesson.questions.length,
                xpEarned: 10,
                mistakes: const [],
                completedAt: DateTime.now(),
              ),
            ),
        true,
      );
      expect(container.read(appControllerProvider).user?.streak, 5);
    },
  );

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
      final trainingLesson = container
          .read(appControllerProvider)
          .lessons
          .firstWhere((lesson) => lesson.isTrainingPack);
      await container
          .read(appControllerProvider.notifier)
          .completeLesson(
            LessonResult(
              lessonId: trainingLesson.id,
              lessonTitle: trainingLesson.title,
              totalQuestions: trainingLesson.questions.length,
              correctAnswers: trainingLesson.questions.length,
              xpEarned: 8,
              mistakes: const [],
              completedAt: DateTime.now(),
            ),
          );

      final state = container.read(appControllerProvider);
      expect(state.todayCompletedLessonIds, isNot(contains(trainingLesson.id)));
      expect(state.todayTrainingSessionIds, contains(trainingLesson.id));
      expect(state.todayCompletedFormalLessonIds, isEmpty);
      expect(state.todayLearningWords, 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LinguaQuestApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Point Tasks'));
      await tester.pumpAndSettle();

      final newLearningTask = find.ancestor(
        of: find.text('Complete New Learning'),
        matching: find.byType(InkWell),
      );
      expect(newLearningTask, findsOneWidget);
      expect(
        find.descendant(of: newLearningTask, matching: find.text('Go +20 XP')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: newLearningTask,
          matching: find.text('Claim +20 XP'),
        ),
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

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Point Tasks'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Weak Word Cleanup'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final cleanupTask = find.ancestor(
      of: find.text('Weak Word Cleanup'),
      matching: find.byType(InkWell),
    );
    expect(cleanupTask, findsOneWidget);
    expect(
      find.descendant(of: cleanupTask, matching: find.text('Go +10 XP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cleanupTask, matching: find.textContaining('Earned')),
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

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Point Tasks'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Weak Word Cleanup'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final cleanupTask = find.ancestor(
      of: find.text('Weak Word Cleanup'),
      matching: find.byType(InkWell),
    );
    expect(cleanupTask, findsOneWidget);
    expect(
      find.descendant(of: cleanupTask, matching: find.text('Go +10 XP')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cleanupTask, matching: find.textContaining('Earned')),
      findsNothing,
    );
  });

  testWidgets('login quick-enter goes straight into the app', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppSecondaryButton, 'Login'));
    await tester.pumpAndSettle();

    // The quick-enter (demo/guest) button on the login screen.
    await tester.tap(
      find.widgetWithText(AppSecondaryButton, 'Enter LinguaQuest'),
    );
    await tester.pumpAndSettle();

    // Landed inside the authenticated home experience.
    expect(find.text('Daily Task Console'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(AppSecondaryButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('learner@lingua.quest'), findsNothing);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'learner@lingua.quest',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
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
    // The startup error is now localized; assert on the interpolated failure
    // detail (locale-independent) rather than the Chinese wording.
    expect(find.textContaining('temporary catalog failure'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(learningRepository.listAttempts, 2);
    expect(find.byIcon(AppIcons.route), findsWidgets);
  });

  testWidgets('session load failure falls back to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_ThrowingSessionAuth()),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('LinguaQuest 启动失败'), findsNothing);
    expect(find.text('LinguaQuest'), findsWidgets);
    expect(find.byIcon(AppIcons.route), findsWidgets);
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

    await tester.fling(find.text('Daily Task Console'), const Offset(-24, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Daily Task Console'), findsOneWidget);

    await tester.drag(find.text('Daily Task Console'), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(find.text('Timed Tests'), findsOneWidget);
    expect(find.byType(AppCard), findsWidgets);
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

    await tester.fling(find.text('Daily Task Console'), const Offset(-80, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Timed Tests'), findsOneWidget);
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: const GoalSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The exam target is now a single HSK book, so size-stability is verified on
    // the daily-goal choices (which still offer several options). The default
    // goal (10) starts selected; tapping another goal must not resize either.
    final goalFive = find.byKey(const ValueKey('choice-5'));
    final goalTwenty = find.byKey(const ValueKey('choice-20'));

    await tester.scrollUntilVisible(
      goalTwenty,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final goalFiveSize = tester.getSize(goalFive);
    final goalTwentySize = tester.getSize(goalTwenty);

    await tester.tap(goalTwenty);
    await tester.pumpAndSettle();

    expect(tester.getSize(goalFive), goalFiveSize);
    expect(tester.getSize(goalTwenty), goalTwentySize);
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
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Study Plan Settings'), findsOneWidget);
    expect(find.text('HSK 1'), findsWidgets);
    expect(find.text('Switch Wordbook'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Daily New Words'), findsOneWidget);
    expect(find.text('Daily Review Limit'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('View Full Wordbook'), findsOneWidget);
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

  test('study plan picker initial date stays inside selectable bounds', () {
    final today = DateTime(2026, 5, 25, 15, 45);
    final firstDate = DateTime(2026, 5, 25);
    final lastDate = DateTime(2028, 5, 24);

    expect(
      clampStudyPlanPickerInitialDate(
        selected: DateTime(2026, 5, 1),
        today: today,
        lastDate: lastDate,
      ),
      firstDate,
    );
    expect(
      clampStudyPlanPickerInitialDate(
        selected: DateTime(2026, 5, 25, 23, 59),
        today: today,
        lastDate: lastDate,
      ),
      firstDate,
    );
    expect(
      clampStudyPlanPickerInitialDate(
        selected: DateTime(2030, 1, 1),
        today: today,
        lastDate: lastDate,
      ),
      lastDate,
    );
  });

  test('study plan reminder time parsing clamps invalid values', () {
    expect(
      parseStudyPlanReminderTime('08:15'),
      const TimeOfDay(hour: 8, minute: 15),
    );
    expect(
      parseStudyPlanReminderTime('99:99'),
      const TimeOfDay(hour: 23, minute: 59),
    );
    expect(
      parseStudyPlanReminderTime('-1:-5'),
      const TimeOfDay(hour: 0, minute: 0),
    );
    expect(
      parseStudyPlanReminderTime('bad'),
      const TimeOfDay(hour: 20, minute: 0),
    );
  });

  test('study plan reminder picker uses input mode', () {
    expect(studyPlanReminderTimePickerEntryMode, TimePickerEntryMode.inputOnly);
  });

  test('learning plan day count uses calendar days', () {
    final plan = StudyPlan(
      id: 'study-plan-calendar-user',
      uid: 'calendar-user',
      wordBookId: 'beginner',
      dailyNewTarget: 10,
      dailyReviewLimit: 20,
      startDate: DateTime(2026, 5, 25),
      targetFinishDate: DateTime(2026, 5, 27, 23, 59),
      reminderTime: '20:00',
      status: 'active',
      createdAt: DateTime(2026, 5, 25, 12),
      updatedAt: DateTime(2026, 5, 25, 12),
    );

    expect(plan.daysLeft(DateTime(2026, 5, 25, 23, 30)), 3);
    expect(plan.daysLeft(DateTime(2026, 5, 27, 23, 30)), 1);
    expect(plan.daysLeft(DateTime(2026, 5, 28)), 0);
  });

  test('study plan JSON fallback target date is date-only', () {
    final plan = StudyPlan.fromJson(const {
      'uid': 'fallback-target-date-user',
      'wordBookId': 'beginner',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
    });

    expect(plan.startDate.hour, 0);
    expect(plan.startDate.minute, 0);
    expect(plan.startDate.second, 0);
    expect(plan.targetFinishDate.hour, 0);
    expect(plan.targetFinishDate.minute, 0);
    expect(plan.targetFinishDate.second, 0);
    expect(plan.targetFinishDate.difference(plan.startDate).inDays, 30);
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
    expect(
      choiceQuestions.every(
        (question) => question.options.first == question.answer,
      ),
      isFalse,
    );
  });

  test('review queues dedupe duplicate custom cards by word text', () {
    final now = DateTime.now();
    final first =
        CustomWord.create(
          id: 'duplicate-first',
          uid: 'dedupe-user',
          word: 'Focus',
          meaning: '专注',
          exampleSentence: 'Focus on one thing.',
          now: now,
        ).copyWith(
          wrongCount: 4,
          nextReviewAt: now.subtract(const Duration(days: 1)),
        );
    final duplicate =
        CustomWord.create(
          id: 'duplicate-second',
          uid: 'dedupe-user',
          word: ' focus ',
          meaning: '焦点',
          exampleSentence: 'The focus is clear.',
          now: now,
        ).copyWith(
          wrongCount: 9,
          nextReviewAt: now.subtract(const Duration(days: 1)),
        );
    final unique =
        CustomWord.create(
          id: 'unique-word',
          uid: 'dedupe-user',
          word: 'Review',
          meaning: '复习',
          exampleSentence: 'Review every day.',
          now: now,
        ).copyWith(
          wrongCount: 2,
          nextReviewAt: now.subtract(const Duration(days: 1)),
        );

    final state = AppState.initial().copyWith(
      customWords: [first, duplicate, unique],
    );

    expect(state.dueWords.map((word) => word.id), [first.id, unique.id]);
    expect(state.weakWords.map((word) => word.id), [first.id, unique.id]);
  });

  test(
    'real wordbook quiz generation shuffles choices and includes spelling',
    () {
      final words = [for (var index = 0; index < 24; index++) _word(index)];
      final lessons = lessonsFromWordBook(
        WordBook(
          id: 'test-book',
          title: '测试词书',
          category: 'exam',
          examType: 'Test',
          coverUrl: '',
          totalWords: words.length,
          includedWords: words.length,
          description: 'Test book',
          wordIds: [for (final word in words) word.id],
          createdAt: DateTime(2026, 6, 5),
          words: words,
        ),
      );
      final formalQuestions = lessons
          .where((lesson) => !lesson.isTrainingPack)
          .expand((lesson) => lesson.questions)
          .toList();
      final choiceQuestions = formalQuestions.where(
        (question) => question.type != QuizQuestionType.spelling,
      );

      expect(
        formalQuestions.map((question) => question.type),
        contains(QuizQuestionType.spelling),
      );
      expect(
        choiceQuestions.any(
          (question) => question.options.first != question.answer,
        ),
        true,
      );
      for (final question in choiceQuestions) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4));
        expect(question.options, contains(question.answer));
      }
    },
  );

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
    final firstFormalWord = state.formalLessons
        .expand((lesson) => lesson.words)
        .firstWhere((word) => word.word.length > 1)
        .word;
    expect(fullTargetCount, greaterThan(state.totalLearningWords));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: const WordbookScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('${state.totalLearningWords} 个目标词'), findsOneWidget);
    expect(find.text('$fullTargetCount 个目标词'), findsNothing);
    await tester.scrollUntilVisible(
      find.text(firstFormalWord),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(firstFormalWord), findsWidgets);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'commute');
    await tester.pumpAndSettle();

    expect(find.text('commute'), findsWidgets);
    expect(find.textContaining('例句片段'), findsWidgets);
  });

  testWidgets(
    'dictionary search matches Chinese definitions and whole corpus',
    (tester) async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'dictionary-search-user',
        name: 'Dora',
        email: 'dora@lingua.quest',
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            theme: AppTheme.light(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentWord = container
          .read(appControllerProvider)
          .formalLessons
          .expand((lesson) => lesson.words)
          .first;

      final directResults = searchDictionaryWords(
        wordBooks: container.read(appControllerProvider).wordBooks,
        currentWordBookId: container
            .read(appControllerProvider)
            .currentWordBookId,
        scope: DictionarySearchScope.currentWordBook,
        query: currentWord.meaning,
        currentWords: container
            .read(appControllerProvider)
            .formalLessons
            .expand((lesson) => lesson.words)
            .toList(),
      );

      expect(
        directResults.map((item) => item.word.id),
        contains(currentWord.id),
      );

      await tester.enterText(find.byType(TextField), currentWord.meaning);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text(currentWord.word), findsWidgets);
      expect(find.textContaining('中文释义'), findsWidgets);

      await tester.tap(find.text('全词库'));
      await tester.pumpAndSettle();
      // Search the whole HSK corpus by an English definition ('teacher' -> 老师).
      await tester.enterText(find.byType(TextField), 'teacher');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('老师'), findsWidgets);
      expect(find.textContaining('中文释义'), findsWidgets);
    },
  );

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

    final trainingLesson = container
        .read(appControllerProvider)
        .lessons
        .firstWhere((lesson) => lesson.isTrainingPack);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LessonPreviewScreen(lessonId: trainingLesson.id),
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

    final trainingLesson = container
        .read(appControllerProvider)
        .lessons
        .firstWhere((lesson) => lesson.isTrainingPack);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: QuizSessionScreen(lessonId: trainingLesson.id),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: QuizSessionScreen(
            lessonId: trainingLesson.id,
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
    'quiz answer options localize distractors from the full lesson pool',
    (tester) async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'quiz-option-locale-user',
        name: 'Olive',
        email: 'olive@lingua.quest',
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

      final lessons = container.read(appControllerProvider).lessons;
      final lesson = lessons.firstWhere(
        (item) =>
            !item.isTrainingPack &&
            item.questions.any(
              (question) => quizOptionsAreMeanings(question.type),
            ),
      );
      final externalWord = Word(
        id: 'external-training-meaning',
        word: 'outside',
        phonetic: '',
        meaning: '外部干扰项',
        definition: 'an item outside the current formal lesson',
        partOfSpeech: 'n',
        exampleSentence: 'This option comes from another pool.',
        exampleTranslation: '这个选项来自另一个词池。',
        imageCue: 'O',
        difficulty: 'Easy',
        tags: const ['training'],
        definitions: const ['外部干扰项'],
        englishDefinitions: const ['an item outside the current formal lesson'],
      );
      final externalLesson = Lesson(
        id: 'lesson-training-external',
        title: 'External training options',
        section: '训练场',
        description: 'Only used as a translation pool source.',
        status: 'locked',
        xpReward: 0,
        estimatedMinutes: 1,
        words: [externalWord],
        questions: const [],
      );
      final originalQuestion = lesson.questions.firstWhere(
        (question) => quizOptionsAreMeanings(question.type),
      );
      final patchedQuestion = QuizQuestion(
        id: originalQuestion.id,
        type: originalQuestion.type,
        prompt: originalQuestion.prompt,
        answer: originalQuestion.answer,
        options: [
          originalQuestion.answer,
          externalWord.meaning,
          ...originalQuestion.options.where(
            (option) =>
                option != originalQuestion.answer &&
                option != externalWord.meaning,
          ),
        ].take(4).toList(growable: false),
        explanation: originalQuestion.explanation,
        word: originalQuestion.word,
      );
      final patchedLessons = [
        for (final item in lessons)
          if (item.id == lesson.id)
            item.copyWith(
              questions: [patchedQuestion, ...item.questions.skip(1)],
            )
          else
            item,
        externalLesson,
      ];
      container.read(appControllerProvider.notifier).state = container
          .read(appControllerProvider)
          .copyWith(lessons: patchedLessons);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light(),
            home: QuizSessionScreen(lessonId: lesson.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(externalWord.primaryDefinitionFor('en')),
        findsOneWidget,
      );
      expect(find.text(externalWord.meaning), findsNothing);
    },
  );

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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
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

    await _openCurrentLessonCards(tester);
    final lesson = _currentLesson(tester);
    await _completeNewWordCards(tester);

    // Wrong-then-right on the first question still records it as a mistake.
    await _answerWrongQuizQuestion(tester, lesson.questions[0]);
    await _advanceCorrectQuizQuestion(tester, lesson.questions[0]);

    await _advanceCorrectQuizQuestion(tester, lesson.questions[1]);
    await _advanceCorrectQuizQuestion(tester, lesson.questions[2]);

    expect(find.text('2/3 · +15 XP · Mistakes saved to review.'), findsOneWidget);
    expect(find.text('Credited +15 XP'), findsOneWidget);
    expect(find.text('+15 XP credited'), findsOneWidget);
    expect(find.text('Total 15 XP'), findsOneWidget);
    expect(
      find.text(
        'Current total 15 XP. XP syncs to your profile, leaderboard, and lucky-draw balance.',
      ),
      findsOneWidget,
    );
    expect(find.text('View XP uses'), findsOneWidget);
    // Cozy Quest cards landed on the lesson result screen.
    expect(find.byType(AppCard), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Go to review center'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to review center'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.byType(AppCard), findsWidgets);
    expect(find.text(lesson.questions[0].word.word), findsWidgets);
    expect(find.text('lesson'), findsWidgets);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
  });

  testWidgets('quiz auto-advances after the feedback delay', (tester) async {
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

    await _openCurrentLessonCards(tester);
    final lesson = _currentLesson(tester);
    await _completeNewWordCards(tester);

    // Advance to the first choice question (skipping any leading spelling ones).
    final choiceIndex = _advanceToFirstChoiceQuestion(lesson);
    for (var i = 0; i < choiceIndex; i++) {
      await _advanceCorrectQuizQuestion(tester, lesson.questions[i]);
    }

    final choiceQuestion = lesson.questions[choiceIndex];
    final nextQuestion = lesson.questions[choiceIndex + 1];
    // The UI is locked to English; the factory bakes the English prompt.
    final choicePrompt = choiceQuestion.prompt;
    final nextPrompt = nextQuestion.prompt;

    // Tapping the correct choice judges instantly — no check/continue buttons.
    await _tapOptionNoSettle(tester, choiceQuestion.answer);

    expect(find.byType(AppCard), findsWidgets);
    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('Correct.'), findsOneWidget);
    expect(
      find.textContaining(
        'Reinforce: ${choiceQuestion.word.word} · ${choiceQuestion.word.meaning}',
      ),
      findsOneWidget,
    );
    // Still on the choice question prompt before the auto-advance delay.
    expect(find.text(choicePrompt), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1499));
    expect(find.text(choicePrompt), findsOneWidget);
    expect(find.text(nextPrompt), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();
    // Advanced to the next question.
    expect(find.text(choicePrompt), findsNothing);
    expect(find.text(nextPrompt), findsOneWidget);
  });

  testWidgets('quiz lets you re-select after a wrong choice', (tester) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'reselect-user',
      name: 'Remy',
      email: 'remy@lingua.quest',
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

    await _openCurrentLessonCards(tester);
    final lesson = _currentLesson(tester);
    await _completeNewWordCards(tester);

    final choiceIndex = _advanceToFirstChoiceQuestion(lesson);
    for (var i = 0; i < choiceIndex; i++) {
      await _advanceCorrectQuizQuestion(tester, lesson.questions[i]);
    }

    final choiceQuestion = lesson.questions[choiceIndex];
    final nextQuestion = lesson.questions[choiceIndex + 1];
    // The UI is locked to English; the factory bakes the English prompt.
    final choicePrompt = choiceQuestion.prompt;
    final nextPrompt = nextQuestion.prompt;

    // A wrong tap shows the retry feedback and does NOT advance or reveal.
    await _tapAnyOptionExceptNoSettle(tester, choiceQuestion.answer);
    expect(find.textContaining('Not quite.'), findsOneWidget);
    // Does not reveal the explanation / reinforce block on a wrong attempt.
    expect(
      find.textContaining(
        'Reinforce: ${choiceQuestion.word.word} · ${choiceQuestion.word.meaning}',
      ),
      findsNothing,
    );
    // Still on the same question (no auto-advance on wrong).
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text(choicePrompt), findsOneWidget);
    expect(find.text(nextPrompt), findsNothing);

    // Re-selecting the correct option now judges correct and advances.
    await _tapOptionNoSettle(tester, choiceQuestion.answer);
    expect(find.textContaining('Correct.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text(nextPrompt), findsOneWidget);
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

    await _openCurrentLessonCards(tester);

    expect(find.text('New Word Cards'), findsOneWidget);
    expect(find.text('Judge your familiarity first'), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Learning Path'), findsOneWidget);
    // Cozy Quest cards landed on the learning path.
    expect(find.byType(AppCard), findsWidgets);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Daily Task Console'), findsOneWidget);

    await _openCurrentLessonCards(tester);
    await _completeNewWordCards(tester);

    final quizLesson = _currentLesson(tester);
    final firstQuestion = quizLesson.questions.first;
    // The UI is locked to English; the factory bakes the English prompt.
    final firstPrompt = firstQuestion.prompt;
    // The question prompt marks that we are on the quiz screen.
    expect(find.text(firstPrompt), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    // A wrong answer registers progress but does not advance.
    await _answerWrongQuizQuestion(tester, firstQuestion);
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Leave Quiz?'), findsOneWidget);

    await tester.tap(find.text('Keep Answering'));
    await tester.pumpAndSettle();

    // Still on the same quiz question after choosing to keep answering.
    expect(find.text(firstPrompt), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Leave Quiz?'), findsNothing);
    expect(find.text(firstPrompt), findsNothing);
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

    await _openCurrentLessonCards(tester);

    expect(find.byType(AppCard), findsWidgets);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Know it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Leave cards?'), findsOneWidget);

    await tester.tap(find.text('Keep studying'));
    await tester.pumpAndSettle();

    expect(find.text('New Word Cards'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Learning Path'), findsOneWidget);
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
      AuthStep.authenticated,
    );
    expect(
      await controller.register('Ava', 'ava@lingua.quest', 'password123'),
      AuthStep.failed,
    );
    expect(
      container.read(appControllerProvider).errorMessage,
      '该邮箱已经注册，请直接登录。',
    );

    await controller.logout();
    expect(
      await controller.register('Ava', 'ava@lingua.quest', 'password123'),
      AuthStep.failed,
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
    expect(state.studyPlan, isNull);
  });

  test(
    'bootstrap derives reminder settings from the loaded study plan',
    () async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'remote-plan-user',
        name: 'Ria',
        email: 'ria@lingua.quest',
        targetExam: 'Daily English',
        level: 'Elementary',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      final loadedPlan = StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      ).copyWith(status: 'paused', reminderTime: '08:15');
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
        'linguaquest.reminderSettings': jsonEncode(
          const DailyReminderSettings(
            enabled: true,
            hour: 22,
            minute: 45,
          ).toJson(),
        ),
      });
      final container = ProviderContainer(
        overrides: [
          studyPlanRepositoryProvider.overrideWithValue(
            _MemoryStudyPlanRepository(loadedPlan),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final state = container.read(appControllerProvider);

      expect(state.studyPlan?.isPaused, true);
      expect(state.reminderSettings.enabled, false);
      expect(state.reminderSettings.hour, 8);
      expect(state.reminderSettings.minute, 15);
    },
  );

  test('reminder settings update syncs into the saved study plan', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'reminder-sync-user',
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
    final studyPlanRepository = _MemoryStudyPlanRepository(
      StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      ).copyWith(status: 'active', reminderTime: '20:00', updatedAt: now),
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = ProviderContainer(
      overrides: [
        studyPlanRepositoryProvider.overrideWithValue(studyPlanRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    await container
        .read(appControllerProvider.notifier)
        .updateReminderSettings(
          const DailyReminderSettings(enabled: false, hour: 7, minute: 30),
        );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('linguaquest.reminderSettings'),
      contains('"hour":7'),
    );
    expect(studyPlanRepository.savedPlan?.reminderTime, '07:30');
    expect(studyPlanRepository.savedPlan?.status, 'paused');
    expect(
      container.read(appControllerProvider).studyPlan?.reminderTime,
      '07:30',
    );
    expect(container.read(appControllerProvider).studyPlan?.status, 'paused');
  });

  test(
    'reminder settings save failure keeps local settings unchanged',
    () async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'reminder-failure-user',
        name: 'Fia',
        email: 'fia@lingua.quest',
        targetExam: 'Daily English',
        level: 'Elementary',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      final plan = StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      ).copyWith(status: 'active', reminderTime: '20:00', updatedAt: now);
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
        'linguaquest.reminderSettings': jsonEncode(
          const DailyReminderSettings(
            enabled: true,
            hour: 20,
            minute: 0,
          ).toJson(),
        ),
      });
      final container = ProviderContainer(
        overrides: [
          studyPlanRepositoryProvider.overrideWithValue(
            _FailingStudyPlanRepository(plan),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      await container
          .read(appControllerProvider.notifier)
          .updateReminderSettings(
            const DailyReminderSettings(enabled: false, hour: 7, minute: 30),
          );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('linguaquest.reminderSettings'),
        contains('"hour":20'),
      );
      expect(container.read(appControllerProvider).reminderSettings.hour, 20);
      expect(
        container.read(appControllerProvider).reminderSettings.enabled,
        true,
      );
      expect(
        container.read(appControllerProvider).studyPlan?.reminderTime,
        '20:00',
      );
      expect(
        container.read(appControllerProvider).errorMessage,
        'remote reminder failure',
      );
      expect(container.read(appControllerProvider).isLoading, false);
    },
  );

  testWidgets('study plan settings shows a loading bar while saving', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'settings-loading-user',
      name: 'Lina',
      email: 'loading@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    final repository = _BlockingStudyPlanRepository(
      StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      ).copyWith(status: 'active', reminderTime: '20:00', updatedAt: now),
    );
    addTearDown(() {
      if (!repository.saveCompleter.isCompleted) {
        repository.saveCompleter.complete(repository.savedPlan);
      }
    });
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [studyPlanRepositoryProvider.overrideWithValue(repository)],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();

    expect(find.byType(AppCard), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Save Study Plan'));
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    repository.saveCompleter.complete(repository.savedPlan);
    await tester.pumpAndSettle();
  });

  testWidgets('study plan settings shows the latest save error', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'settings-error-user',
      name: 'Serena',
      email: 'settings-error@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    final plan = StudyPlan.defaultsFor(
      uid: profile.uid,
      targetExam: profile.targetExam,
      dailyGoal: profile.dailyGoal,
    ).copyWith(status: 'active', reminderTime: '20:00', updatedAt: now);
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyPlanRepositoryProvider.overrideWithValue(
            _FailingStudyPlanRepository(
              plan,
              message: 'study plan save failure',
            ),
          ),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Study Plan'));
    await tester.pumpAndSettle();

    expect(find.text('study plan save failure'), findsOneWidget);
    expect(find.text('暂时无法保存计划。'), findsNothing);
  });

  test(
    'resetting a study plan updates custom words without per-word writes',
    () async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'reset-parallel-user',
        name: 'Rex',
        email: 'rex@lingua.quest',
        targetExam: 'Daily English',
        level: 'Elementary',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      final plan = StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      );
      final customWordRepository = _ConcurrentCustomWordRepository()
        ..words.addAll(
          List.generate(
            4,
            (index) =>
                CustomWord.create(
                  id: 'reset-word-$index',
                  uid: profile.uid,
                  word: 'reset-$index',
                  meaning: 'reset meaning $index',
                  exampleSentence: 'Reset word $index.',
                  now: now,
                ).copyWith(
                  masteryLevel: 4,
                  correctCount: 6,
                  wrongCount: 2,
                  nextReviewAt: now.add(const Duration(days: 7)),
                ),
          ),
        );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });
      final container = ProviderContainer(
        overrides: [
          customWordRepositoryProvider.overrideWithValue(customWordRepository),
          studyPlanRepositoryProvider.overrideWithValue(
            _MemoryStudyPlanRepository(plan),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      expect(
        await container.read(appControllerProvider.notifier).resetStudyPlan(),
        true,
      );

      expect(customWordRepository.maxConcurrentUpdates, 0);
      final resetAt = container
          .read(appControllerProvider)
          .studyPlan!
          .updatedAt;
      for (final word in container.read(appControllerProvider).customWords) {
        expect(word.masteryLevel, 0);
        expect(word.correctCount, 0);
        expect(word.wrongCount, 0);
        expect(word.nextReviewAt, resetAt);
        expect(word.updatedAt, resetAt);
      }
    },
  );

  testWidgets('study plan save allows an unchanged expired target date', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'expired-date-user',
      name: 'Eda',
      email: 'eda@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    final studyPlanRepository = _MemoryStudyPlanRepository(
      StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      ).copyWith(targetFinishDate: DateTime(2026, 1, 15)),
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyPlanRepositoryProvider.overrideWithValue(studyPlanRepository),
        ],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Study Plan'));
    await tester.pumpAndSettle();

    expect(
      find.text('Target completion date cannot be earlier than today.'),
      findsNothing,
    );
    expect(find.text('Study plan saved.'), findsOneWidget);
    expect(
      studyPlanRepository.savedPlan?.targetFinishDate,
      DateTime(2026, 1, 15),
    );
  });

  test('study plan save rejects a changed expired target date', () {
    final today = DateTime(2026, 5, 25, 12);

    expect(
      rejectChangedExpiredTargetFinishDate(
        finishDate: DateTime(2026, 1, 15, 8),
        originalFinishDate: DateTime(2026, 1, 15, 20),
        today: today,
      ),
      false,
    );
    expect(
      rejectChangedExpiredTargetFinishDate(
        finishDate: DateTime(2026, 2, 1),
        originalFinishDate: DateTime(2026, 1, 15),
        today: today,
      ),
      true,
    );
    expect(
      rejectChangedExpiredTargetFinishDate(
        finishDate: DateTime(2026, 5, 25),
        originalFinishDate: DateTime(2026, 1, 15),
        today: today,
      ),
      false,
    );
  });

  testWidgets('study plan settings resyncs when the saved plan changes', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'settings-resync-user',
      name: 'Ria',
      email: 'settings-resync@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    final initialPlan =
        StudyPlan.defaultsFor(
          uid: profile.uid,
          targetExam: profile.targetExam,
          dailyGoal: profile.dailyGoal,
        ).copyWith(
          dailyNewTarget: 10,
          dailyReviewLimit: 20,
          reminderTime: '20:00',
          updatedAt: now,
        );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = ProviderContainer(
      overrides: [
        studyPlanRepositoryProvider.overrideWithValue(
          _MemoryStudyPlanRepository(initialPlan),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();

    List<String> visibleNumberFieldValues() => tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller?.text)
        .whereType<String>()
        .toList();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(visibleNumberFieldValues(), contains('10'));
    final updatedPlan = initialPlan.copyWith(
      dailyNewTarget: 33,
      dailyReviewLimit: 44,
      reminderTime: '99:99',
      updatedAt: now.add(const Duration(minutes: 1)),
    );
    expect(
      await container
          .read(appControllerProvider.notifier)
          .updateStudyPlan(updatedPlan),
      true,
    );
    await tester.pumpAndSettle();

    expect(visibleNumberFieldValues(), contains('33'));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(visibleNumberFieldValues(), contains('44'));
    expect(
      container.read(appControllerProvider).studyPlan?.dailyReviewLimit,
      44,
    );
  });

  testWidgets('study plan numeric fields accept digits only', (tester) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'settings-digits-user',
      name: 'Dina',
      email: 'digits@lingua.quest',
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
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();

    Iterable<EditableText> digitOnlyFields() => tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where(
          (field) =>
              field.inputFormatters?.contains(
                FilteringTextInputFormatter.digitsOnly,
              ) ??
              false,
        );

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(digitOnlyFields(), hasLength(2));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(
      digitOnlyFields().where((field) => field.controller.text == '20'),
      hasLength(1),
    );
  });

  testWidgets('study plan fallback initialization preserves unsaved edits', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'settings-fallback-user',
      name: 'Fay',
      email: 'settings-fallback@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        studyPlanRepositoryProvider.overrideWithValue(
          _MemoryStudyPlanRepository(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    container.read(appControllerProvider.notifier).state = container
        .read(appControllerProvider)
        .copyWith(studyPlan: null);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.text('Adjust Plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjust Plan'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    field.controller?.text = '77';
    await container
        .read(appControllerProvider.notifier)
        .updateThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    final updatedField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(updatedField.controller?.text, '77');
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
    const completedLessonId = 'hsk1-lesson-1';
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: TargetWordDetailScreen(wordId: targetWord.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('加入生词本'), findsOneWidget);
    expect(find.byType(AppCard), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, '加入生词本'));
    await tester.pumpAndSettle();

    final savedWords = container.read(appControllerProvider).customWords;
    expect(savedWords.any((word) => word.word == targetWord.word), true);
    expect(find.widgetWithText(FilledButton, '移出生词本'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '移出生词本'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(appControllerProvider)
          .customWords
          .any((word) => word.word == targetWord.word),
      false,
    );
    expect(find.widgetWithText(FilledButton, '加入生词本'), findsOneWidget);
  });

  testWidgets(
    'target word detail shows rich dictionary content and AI context',
    (tester) async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'target-detail-rich-user',
        name: 'Riley',
        email: 'riley@lingua.quest',
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
      // The runtime wordbook is the HSK book; use a real entry with rich
      // Chinese/English definitions (爱) instead of the old IELTS 'abstract'.
      final word = container
          .read(appControllerProvider)
          .wordBooks
          .expand((book) => book.words)
          .firstWhere(
            (item) =>
                item.definitions.isNotEmpty &&
                item.englishDefinitions.isNotEmpty,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            theme: AppTheme.light(),
            home: TargetWordDetailScreen(wordId: word.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chinese (HSK) words show pinyin once, without the UK/US split.
      expect(find.text(word.phoneticUK), findsWidgets);
      expect(find.text('英 /${word.phoneticUK}/'), findsNothing);
      expect(find.text('美 /${word.phoneticUS}/'), findsNothing);
      // Chinese (HSK) words drop the redundant Chinese-definitions block; only
      // the English definitions remain.
      expect(find.text('中文释义'), findsNothing);
      expect(find.text('英文释义'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('AI 学习'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // HSK entries carry no example sentence, so the AI helper shows the
      // no-example prompt that references the word.
      expect(find.textContaining('围绕 ${word.word} 提问'), findsOneWidget);
    },
  );

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: WordDetailScreen(wordId: word.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('context'), findsWidgets);
    expect(find.byType(AppCard), findsWidgets);
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

    expect(find.text('Daily Task Console'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open Word Card'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Open Word Card'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Wordbook'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wordbook'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('context'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.byType(AppCard), findsWidgets);
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
    expect(state.studyPlan, isNotNull);
    // The runtime collapses every book id to the single HSK book.
    expect(state.studyPlan?.wordBookId, 'hsk1');
    expect(state.currentWordBookId, 'hsk1');
    expect(state.user?.dailyGoal, state.studyPlan?.dailyNewTarget);
    expect(state.studyPlan?.dailyNewTarget, greaterThan(0));
    expect(state.studyPlan?.targetFinishDate.year, deadline.year);
    expect(state.currentWordBook?.id, 'hsk1');
    expect(state.lessons, isNotEmpty);
  });

  test('API wordbook fallback does not poison the remote cache', () async {
    final apiClient = ApiClient();
    var attempts = 0;
    final fallbackBook = _book('fallback-book', 'Fallback Book');
    final serverBook = _book('server-book', 'Server Book');
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          attempts++;
          if (attempts == 1) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'offline',
              ),
            );
            return;
          }
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              data: [serverBook.toJson()],
              statusCode: 200,
            ),
          );
        },
      ),
    );
    final repository = ApiLearningRepository(
      apiClient,
      fallbackLoader: _FakeWordBookAssetLoader([fallbackBook]),
    );

    final offlineBooks = await repository.listWordBooks();
    final onlineBooks = await repository.listWordBooks();

    expect(offlineBooks.single.id, fallbackBook.id);
    expect(onlineBooks.single.id, serverBook.id);
    expect(attempts, 2);
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

  test('lesson completion survives reward event failures', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'lesson-reward-failure-user',
      name: 'Lee',
      email: 'lee@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardTaskRepositoryProvider.overrideWithValue(
          _RecordEventFailingRewardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final lesson = seedLessons().first;
    final result = LessonResult(
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      totalQuestions: lesson.questions.length,
      correctAnswers: lesson.questions.length,
      xpEarned: 10,
      mistakes: const [],
      completedAt: DateTime.now(),
    );

    expect(
      await container
          .read(appControllerProvider.notifier)
          .completeLesson(result),
      true,
    );
    final state = container.read(appControllerProvider);
    expect(state.completedLessonIds, contains(lesson.id));
    expect(state.lastResult?.lessonId, result.lessonId);
    expect(state.lastResult?.xpEarned, 10);
    expect(state.user?.xp, 10);
  });

  test('word review survives reward event failures', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'review-reward-failure-user',
      name: 'Rue',
      email: 'rue@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardTaskRepositoryProvider.overrideWithValue(
          _RecordEventFailingRewardRepository(),
        ),
      ],
    );
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
    expect(container.read(appControllerProvider).todayReviewWordIds, {
      dueWord.id,
    });
  });

  test('wrong cleanup records one combined reward event', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'single-cleanup-event-user',
      name: 'Wyn',
      email: 'wyn@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      createdAt: now,
      updatedAt: now,
      xp: 0,
      streak: 0,
    );
    final customWordRepository = _ConcurrentCustomWordRepository()
      ..words.add(
        CustomWord.create(
          id: 'cleanup-word',
          uid: profile.uid,
          word: 'cleanup',
          meaning: '清理',
          exampleSentence: 'Cleanup removes repeated reward calls.',
          now: now,
        ).copyWith(wrongCount: 2, nextReviewAt: now),
      );
    final rewardRepository = _RecordingRewardRepository();
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = ProviderContainer(
      overrides: [
        customWordRepositoryProvider.overrideWithValue(customWordRepository),
        rewardTaskRepositoryProvider.overrideWithValue(rewardRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    expect(
      await container
          .read(appControllerProvider.notifier)
          .reviewWord('cleanup-word', true),
      true,
    );

    expect(rewardRepository.recordedEvents, [RewardEventType.wrongCleanup]);
    expect(
      container
          .read(appControllerProvider)
          .rewardTasks
          .singleWhere((task) => task.id == 'reviewDone')
          .isClaimable,
      true,
    );
    expect(
      container
          .read(appControllerProvider)
          .rewardTasks
          .singleWhere((task) => task.id == 'wrongCleanup')
          .isClaimable,
      true,
    );
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
      await controller.claimLocalReward(
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
      await controller.claimLocalReward(
        id: 'daily-checkin',
        points: 5,
        isAvailable: true,
      ),
      false,
    );
    expect(container.read(appControllerProvider).user?.xp, 35);
  });

  test('discover reward claim requires explicit claimed response', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'null-claim-user',
      name: 'Nia',
      email: 'nia@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardTaskRepositoryProvider.overrideWithValue(
          _NullClaimRewardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    expect(
      await container
          .read(appControllerProvider.notifier)
          .claimReward('dailyCheckIn'),
      false,
    );
    expect(container.read(appControllerProvider).user?.xp, 30);
  });

  test('claiming a server-granted reward syncs local claimed state', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'already-granted-user',
      name: 'Sync',
      email: 'sync@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardRepositoryProvider.overrideWithValue(_AlreadyGrantedReward()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    final controller = container.read(appControllerProvider.notifier);

    expect(
      await controller.claimLocalReward(
        id: 'daily-checkin',
        points: 5,
        isAvailable: true,
      ),
      true,
    );

    final state = container.read(appControllerProvider);
    expect(state.errorMessage, isNull);
    expect(state.user?.xp, 30);
    expect(state.todayClaimedRewardIds, contains('daily-checkin'));

    final prefs = await SharedPreferences.getInstance();
    // P2b: rewards are now saved under the scoped key (zh::hsk1).
    expect(
      prefs.getStringList('linguaquest.today.rewards.zh::hsk1'),
      contains('daily-checkin'),
    );
  });

  test('incomplete reward claim shows localized error message', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'incomplete-claim-user',
      name: 'Ivy',
      email: 'ivy@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardTaskRepositoryProvider.overrideWithValue(
          _IncompleteClaimRewardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    expect(
      await container
          .read(appControllerProvider.notifier)
          .claimReward('dailyCheckIn'),
      false,
    );
    final state = container.read(appControllerProvider);
    expect(state.errorMessage, '该任务尚未完成，无法领取奖励。');
    expect(state.pendingRewardTaskIds, isNot(contains('dailyCheckIn')));
  });

  test('server reward user snapshot does not patch profile again', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'server-snapshot-user',
      name: 'Sol',
      email: 'sol@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      createdAt: now,
      updatedAt: now,
      xp: 30,
      streak: 1,
    );
    final serverUser = profile.copyWith(xp: 35, updatedAt: now);
    SharedPreferences.setMockInitialValues({});
    final authRepository = _SnapshotAuthRepository(profile);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        rewardTaskRepositoryProvider.overrideWithValue(
          _ServerUserRewardRepository(serverUser),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();

    expect(
      await container.read(appControllerProvider.notifier).checkInToday(),
      true,
    );
    expect(container.read(appControllerProvider).user?.xp, 35);
    expect(authRepository.updateProfileCalls, 0);
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
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LinguaQuestApp)),
    );
    final firstWord = container
        .read(appControllerProvider)
        .currentLesson!
        .words
        .first;
    await tester.tap(find.textContaining('Start'));
    await tester.pumpAndSettle();

    expect(find.text("Today's mixed pack"), findsOneWidget);
    expect(find.text(firstWord.word), findsWidgets);

    await tester.tap(find.text("Don't know"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recognition'));
    await tester.pumpAndSettle();

    // Instant judgment: a wrong tap marks the option red but keeps the same
    // question open for re-selection (no auto-advance, no check button).
    await _tapAnyOptionExceptNoSettle(tester, firstWord.meaning);
    await tester.pump();
    expect(find.text('Check'), findsNothing);
    expect(find.textContaining(firstWord.word), findsWidgets);

    // Selecting the correct answer settles the step and auto-advances after the
    // 1500ms timer.
    await _tapOptionNoSettle(tester, firstWord.meaning);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Add to later recall'), findsOneWidget);

    // Drain the top-notice auto-dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'mixed study question step instant-judges: wrong stays, correct auto-advances',
    (tester) async {
      final now = DateTime(2026, 5, 25);
      final profile = UserProfile(
        uid: 'instant-judge-user',
        name: 'Ivy',
        email: 'ivy@lingua.quest',
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LinguaQuestApp)),
      );
      final firstWord = container
          .read(appControllerProvider)
          .currentLesson!
          .words
          .first;
      await tester.tap(find.textContaining('Start'));
      await tester.pumpAndSettle();

      // Enter the recognition question for the first new word.
      await tester.tap(find.text("Don't know"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start recognition'));
      await tester.pumpAndSettle();
      // No check button: question steps judge on tap.
      expect(find.text('Check'), findsNothing);
      // The recall card that follows the question is not on screen yet.
      expect(find.text('Add to later recall'), findsNothing);

      // A wrong tap does NOT advance: even after the auto-advance window would
      // have elapsed, the follow-up recall card has not appeared.
      await _tapAnyOptionExceptNoSettle(tester, firstWord.meaning);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
      expect(find.text('Add to later recall'), findsNothing);

      // A correct tap settles the step. Before the 1500ms timer fires we have
      // not advanced; after it fires the follow-up recall card appears.
      await _tapOptionNoSettle(tester, firstWord.meaning);
      expect(find.text('Add to later recall'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(find.text('Add to later recall'), findsOneWidget);

      // Drain the top-notice auto-dismiss timer.
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();
    },
  );

  test('mixed study completion records learned target words', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'mixed-target-user',
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

    final controller = container.read(appControllerProvider.notifier);
    await controller.bootstrap();
    final lesson = container.read(appControllerProvider).currentLesson!;

    final succeeded = await controller.completeMixedStudySession(
      lessonId: 'daily-mixed-session',
      totalQuestions: lesson.questions.length,
      correctAnswers: lesson.questions.length,
      mistakeWordIds: const [],
      answerEvents: const [],
      startedAt: now,
      endedAt: now.add(const Duration(minutes: 5)),
      completeCurrentLesson: true,
      xpEarned: 20,
    );

    expect(succeeded, isTrue);
    final learnedWordIds = {
      for (final word in container.read(appControllerProvider).userWords)
        word.wordId,
    };
    expect(learnedWordIds, containsAll(lesson.words.map((word) => word.id)));
  });

  testWidgets('lesson result ignores stale results from another lesson', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'stale-result-user',
      name: 'Stale',
      email: 'stale@lingua.quest',
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
    expect(
      await container
          .read(appControllerProvider.notifier)
          .completeLesson(
            LessonResult(
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              totalQuestions: lesson.questions.length,
              correctAnswers: lesson.questions.length,
              xpEarned: lesson.xpReward,
              mistakes: const [],
              completedAt: now,
            ),
          ),
      true,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const LessonResultScreen(expectedLessonId: 'different-lesson'),
        ),
      ),
    );

    expect(find.text('还没有课程结果'), findsOneWidget);
    expect(find.text(lesson.title), findsNothing);
  });

  test('lesson completion survives reward grant failure', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'lesson-reward-fail-user',
      name: 'Lex',
      email: 'lex@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardRepositoryProvider.overrideWithValue(_ThrowingReward()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final lesson = seedLessons().first;
    final completed = await container
        .read(appControllerProvider.notifier)
        .completeLesson(
          LessonResult(
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            totalQuestions: lesson.questions.length,
            correctAnswers: lesson.questions.length,
            xpEarned: lesson.xpReward,
            mistakes: const [],
            completedAt: now,
          ),
        );
    final state = container.read(appControllerProvider);

    expect(completed, true);
    expect(state.completedLessonIds, contains(lesson.id));
    expect(state.lastResult?.lessonId, lesson.id);
    expect(state.lastResult?.xpEarned, 0);
    expect(state.user?.xp, 0);
  });

  test('review progress survives reward grant failure', () async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'review-reward-fail-user',
      name: 'Rev',
      email: 'rev@lingua.quest',
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
    final container = ProviderContainer(
      overrides: [
        rewardRepositoryProvider.overrideWithValue(_ThrowingReward()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final dueWord = container.read(appControllerProvider).dueWords.first;
    final reviewed = await container
        .read(appControllerProvider.notifier)
        .reviewWord(dueWord.id, true);
    final state = container.read(appControllerProvider);
    final reviewedWord = state.customWords.firstWhere(
      (word) => word.id == dueWord.id,
    );

    expect(reviewed, true);
    expect(reviewedWord.correctCount, dueWord.correctCount + 1);
    expect(state.todayReviewWordIds, contains(dueWord.id));
    expect(state.user?.xp, 0);
  });

  test(
    'daily rollover clears stale persisted daily keys before saving',
    () async {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'rollover-user',
        name: 'Rollover',
        email: 'rollover@lingua.quest',
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
        'linguaquest.today.date': '2000-01-01',
        'linguaquest.today.lessons': ['yesterday-lesson'],
        'linguaquest.today.reviews': ['yesterday-review'],
        'linguaquest.today.training': ['yesterday-training'],
        'linguaquest.today.rewards': ['yesterday-reward'],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final training = container
          .read(appControllerProvider)
          .lessons
          .firstWhere((lesson) => lesson.isTrainingPack);
      expect(
        await container
            .read(appControllerProvider.notifier)
            .completeLesson(
              LessonResult(
                lessonId: training.id,
                lessonTitle: training.title,
                totalQuestions: training.questions.length,
                correctAnswers: training.questions.length,
                xpEarned: training.xpReward,
                mistakes: const [],
                completedAt: now,
              ),
            ),
        true,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('linguaquest.today.date'), _todayDateKey(now));
      // P2b: daily state keys are now scoped (zh::hsk1). Rollover clears scoped
      // keys; the legacy global keys are kept as a safety copy but not used.
      expect(prefs.getStringList('linguaquest.today.lessons.zh::hsk1'), isNull);
      expect(prefs.getStringList('linguaquest.today.reviews.zh::hsk1'), isNull);
      expect(prefs.getStringList('linguaquest.today.rewards.zh::hsk1'), isNull);
      expect(
        prefs.getStringList('linguaquest.today.training.zh::hsk1'),
        contains(training.id),
      );
      expect(
        prefs.getStringList('linguaquest.today.training.zh::hsk1'),
        isNot(contains('yesterday-training')),
      );
    },
  );

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
    final lesson = container.read(appControllerProvider).formalLessons.first;
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

    final reviewButton = find.widgetWithText(AppSecondaryButton, 'Review');
    await tester.scrollUntilVisible(
      reviewButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage review queue'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add mistake cards'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Add selected (2)'), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey('mistake-select-${mistakes[0].word.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('mistake-select-${mistakes[1].word.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add selected (0)'), findsOneWidget);

    await container
        .read(appControllerProvider.notifier)
        .updateThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.text('Add selected (0)'), findsOneWidget);
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

      final reviewButton = find.widgetWithText(AppSecondaryButton, 'Review');
      await tester.scrollUntilVisible(
        reviewButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage review queue'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Add mistake cards'),
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
      expect(find.text('Add selected (6)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Add selected (6)'),
        300,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add selected (6)'));
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

Future<void> _openCurrentLessonCards(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LinguaQuestApp)),
  );
  container.read(routerProvider).go('/learn');
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(AppIcons.playArrow).first);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(AppPrimaryButton, 'Start Learning'));
  await tester.pumpAndSettle();
}

Lesson _currentLesson(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LinguaQuestApp)),
  );
  return container.read(appControllerProvider).currentLesson!;
}

/// Answers [question] correctly in the [QuizSessionScreen] immediate-judgment
/// flow and advances past the 1500ms auto-advance to the next question (or to
/// the result screen if it was the last). For choice questions this taps the
/// correct option; for spelling it enters the answer and taps the check button.
Future<void> _advanceCorrectQuizQuestion(
  WidgetTester tester,
  QuizQuestion question,
) async {
  if (question.type == QuizQuestionType.spelling) {
    await tester.enterText(find.byType(TextField), question.answer);
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();
  } else {
    await _tapOptionNoSettle(tester, question.answer);
  }
  // Run the auto-advance timer to completion, then let navigation settle.
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

/// Returns the index of the first non-spelling (choice) question in [lesson]
/// that is followed by at least one more question. Fails if none exists.
int _advanceToFirstChoiceQuestion(Lesson lesson) {
  for (var i = 0; i < lesson.questions.length - 1; i++) {
    if (lesson.questions[i].type != QuizQuestionType.spelling) return i;
  }
  fail('No non-final choice question found in lesson ${lesson.id}.');
}

/// Answers [question] incorrectly in the [QuizSessionScreen] immediate-judgment
/// flow. The screen stays on the same question (no auto-advance on wrong).
Future<void> _answerWrongQuizQuestion(
  WidgetTester tester,
  QuizQuestion question,
) async {
  if (question.type == QuizQuestionType.spelling) {
    await tester.enterText(find.byType(TextField), '${question.answer}x');
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();
  } else {
    await _tapAnyOptionExceptNoSettle(tester, question.answer);
  }
}

/// Taps the option labelled [label] without pumping past the auto-advance
/// timer (unlike [_tapOption] which calls pumpAndSettle).
Future<void> _tapOptionNoSettle(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(WordChoiceButton, label).first;
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  final rect = tester.getRect(finder);
  await tester.tapAt(Offset(rect.left + 24, rect.top + 24));
  await tester.pump();
}

/// Taps any choice option except the one labelled [label], without pumping
/// past the auto-advance timer.
Future<void> _tapAnyOptionExceptNoSettle(
  WidgetTester tester,
  String label,
) async {
  final candidates = find.byType(WordChoiceButton).evaluate();
  for (final element in candidates) {
    final option = find.byElementPredicate(
      (candidate) => identical(candidate, element),
    );
    final hasExcludedLabel = find
        .descendant(of: option, matching: find.text(label))
        .evaluate()
        .isNotEmpty;
    if (hasExcludedLabel) continue;
    await tester.ensureVisible(option);
    await tester.pump();
    final rect = tester.getRect(option);
    await tester.tapAt(Offset(rect.left + 24, rect.top + 24));
    await tester.pump();
    return;
  }
  fail('No option found except $label');
}

Future<void> _completeNewWordCards(WidgetTester tester) async {
  for (var index = 0; index < 10; index++) {
    final knowIt = find.widgetWithText(OutlinedButton, 'Know it');
    await tester.ensureVisible(knowIt);
    await tester.pumpAndSettle();
    await tester.tap(knowIt);
    await tester.pumpAndSettle();
    final quizEntry = find.text('Start context practice');
    if (quizEntry.evaluate().isNotEmpty) {
      await tester.ensureVisible(quizEntry);
      await tester.pumpAndSettle();
      await tester.tap(quizEntry);
      await tester.pumpAndSettle();
      return;
    }
    final nextCard = find.text('Next card');
    await tester.ensureVisible(nextCard);
    await tester.pumpAndSettle();
    await tester.tap(nextCard);
    await tester.pumpAndSettle();
  }
  fail('Could not reach the quiz entry after completing word cards.');
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
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw Exception('register failed');
  }

  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) {
    throw Exception('verifyEmail failed');
  }

  @override
  Future<void> resendCode(String email) async {
    throw Exception('resendCode failed');
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;

  @override
  Future<void> logout() async {}
}

class _SnapshotAuthRepository implements AuthRepository {
  _SnapshotAuthRepository(this._profile);

  final UserProfile _profile;
  int updateProfileCalls = 0;

  @override
  Future<UserProfile?> loadSession() async => _profile;

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw Exception('login not expected');
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw Exception('register not expected');
  }

  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) {
    throw Exception('verifyEmail not expected');
  }

  @override
  Future<void> resendCode(String email) async {
    throw Exception('resendCode not expected');
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    updateProfileCalls++;
    return profile;
  }

  @override
  Future<void> logout() async {}
}

class _ThrowingSessionAuth extends _FailingAuth {
  @override
  Future<UserProfile?> loadSession() {
    throw Exception('session expired');
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
  Future<void> clearOfflineCache() async {}

  @override
  Future<LearningProgress?> loadLearningProgress(DateTime now) async => null;

  @override
  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) async =>
      lessons;

  @override
  Future<void> recordStudySession(StudySession session) async {}

  @override
  Future<void> recordExerciseRecords(List<ExerciseRecord> records) async {}

  @override
  Future<RewardClaimResult?> claimReward({
    required String id,
    required int points,
    required DateTime now,
  }) async {
    return null;
  }
}

class _FlakyLearningRepository implements LearningRepository {
  int listAttempts = 0;

  @override
  Future<List<WordBook>> listWordBooks() async => const [];

  @override
  Future<void> clearOfflineCache() async {}

  @override
  Future<List<Lesson>> listLessons() async {
    listAttempts++;
    if (listAttempts == 1) {
      throw Exception('temporary catalog failure');
    }
    return seedLessons();
  }

  @override
  Future<LearningProgress?> loadLearningProgress(DateTime now) async => null;

  @override
  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) =>
      listLessons();

  @override
  Future<void> recordStudySession(StudySession session) async {}

  @override
  Future<void> recordExerciseRecords(List<ExerciseRecord> records) async {}

  @override
  Future<RewardClaimResult?> claimReward({
    required String id,
    required int points,
    required DateTime now,
  }) async {
    return null;
  }
}

class _MemoryStudyPlanRepository implements StudyPlanRepository {
  _MemoryStudyPlanRepository(this.savedPlan);

  StudyPlan? savedPlan;

  @override
  Future<StudyPlan?> load(String uid) async => savedPlan;

  @override
  Future<StudyPlan> reset(StudyPlan plan) async {
    final now = DateTime.now();
    final resetPlan = plan.copyWith(
      startDate: DateTime(now.year, now.month, now.day),
      status: 'active',
      updatedAt: now,
    );
    savedPlan = resetPlan;
    return resetPlan;
  }

  @override
  Future<StudyPlan> save(StudyPlan plan) async {
    savedPlan = plan;
    return plan;
  }
}

class _FailingStudyPlanRepository implements StudyPlanRepository {
  _FailingStudyPlanRepository(
    this.savedPlan, {
    this.message = 'remote reminder failure',
  });

  final StudyPlan savedPlan;
  final String message;

  @override
  Future<StudyPlan?> load(String uid) async => savedPlan;

  @override
  Future<StudyPlan> reset(StudyPlan plan) async => savedPlan;

  @override
  Future<StudyPlan> save(StudyPlan plan) async {
    throw StateError(message);
  }
}

class _BlockingStudyPlanRepository implements StudyPlanRepository {
  _BlockingStudyPlanRepository(this.savedPlan);

  StudyPlan savedPlan;
  final saveCompleter = Completer<StudyPlan>();

  @override
  Future<StudyPlan?> load(String uid) async => savedPlan;

  @override
  Future<StudyPlan> reset(StudyPlan plan) async => savedPlan;

  @override
  Future<StudyPlan> save(StudyPlan plan) async {
    savedPlan = plan;
    return saveCompleter.future;
  }
}

class _FakeWordBookAssetLoader extends WordBookAssetLoader {
  _FakeWordBookAssetLoader(this.books);

  final List<WordBook> books;

  @override
  Future<List<WordBook>> loadWordBooks() async => books;
}

class _ConcurrentCustomWordRepository implements CustomWordRepository {
  final List<CustomWord> words = [];
  int _activeCreates = 0;
  int _activeUpdates = 0;
  int maxConcurrentCreates = 0;
  int maxConcurrentUpdates = 0;

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
    _activeUpdates++;
    if (_activeUpdates > maxConcurrentUpdates) {
      maxConcurrentUpdates = _activeUpdates;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final index = words.indexWhere((item) => item.id == word.id);
    if (index == -1) {
      words.add(word);
    } else {
      words[index] = word;
    }
    _activeUpdates--;
    return word;
  }
}

class _RecordEventFailingRewardRepository implements RewardTaskRepository {
  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async => _emptySnapshot();

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async =>
      _emptySnapshot();

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async => _emptySnapshot();

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async {
    throw Exception('reward service unavailable');
  }

  RewardTaskSnapshot _emptySnapshot() {
    return RewardTaskSnapshot(
      dateKey: _todayDateKey(DateTime.now()),
      tasks: const [],
    );
  }
}

class _RecordingRewardRepository implements RewardTaskRepository {
  final List<RewardEventType> recordedEvents = [];
  bool _reviewDone = false;
  bool _wrongCleanupDone = false;

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async =>
      _snapshot();

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async {
    recordedEvents.add(type);
    if (type == RewardEventType.reviewDone) {
      _reviewDone = true;
    }
    if (type == RewardEventType.wrongCleanup) {
      _reviewDone = true;
      _wrongCleanupDone = true;
    }
    return _snapshot();
  }

  Future<RewardTaskSnapshot> _snapshot() async {
    return RewardTaskSnapshot(
      dateKey: _todayDateKey(DateTime.now()),
      tasks: [
        DailyRewardTask(
          id: 'reviewDone',
          title: '完成复习',
          condition: '完成今日到期复习',
          points: 15,
          targetRoute: '/study/review',
          status: _reviewDone
              ? DailyRewardTaskStatus.claimable
              : DailyRewardTaskStatus.incomplete,
        ),
        DailyRewardTask(
          id: 'wrongCleanup',
          title: '错词清理',
          condition: '今日错词再次答对',
          points: 10,
          targetRoute: '/review',
          status: _wrongCleanupDone
              ? DailyRewardTaskStatus.claimable
              : DailyRewardTaskStatus.incomplete,
        ),
      ],
    );
  }
}

class _NullClaimRewardRepository implements RewardTaskRepository {
  static const _task = DailyRewardTask(
    id: 'dailyCheckIn',
    title: '每日签到',
    condition: '当天打开并点击签到',
    points: 5,
    targetRoute: '/discover',
    status: DailyRewardTaskStatus.claimable,
  );

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async {
    return Future.value(
      const RewardTaskSnapshot(dateKey: '2026-05-25', tasks: [_task]),
    );
  }

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async => _snapshot();

  Future<RewardTaskSnapshot> _snapshot() async {
    return const RewardTaskSnapshot(dateKey: '2026-05-25', tasks: [_task]);
  }
}

class _IncompleteClaimRewardRepository implements RewardTaskRepository {
  static const _task = DailyRewardTask(
    id: 'dailyCheckIn',
    title: '每日签到',
    condition: '当天打开并点击签到',
    points: 5,
    targetRoute: '/discover',
    status: DailyRewardTaskStatus.claimable,
  );

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async {
    final requestOptions = RequestOptions(path: '/rewards/tasks/$taskId/claim');
    throw DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        statusCode: 409,
        data: const {'error': 'task_not_complete'},
      ),
    );
  }

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async => _snapshot();

  Future<RewardTaskSnapshot> _snapshot() async {
    return const RewardTaskSnapshot(dateKey: '2026-05-25', tasks: [_task]);
  }
}

class _ServerUserRewardRepository implements RewardTaskRepository {
  const _ServerUserRewardRepository(this._user);

  final UserProfile _user;

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async =>
      _snapshot(user: _user);

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async =>
      _snapshot(user: _user, claimed: true);

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async => _snapshot();

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async => _snapshot();

  RewardTaskSnapshot _snapshot({UserProfile? user, bool? claimed}) {
    return RewardTaskSnapshot(
      dateKey: '2026-05-25',
      tasks: const [],
      user: user,
      claimed: claimed,
    );
  }
}

class _ThrowingReward implements RewardRepository {
  @override
  Future<PointGrantResult> grantPoints({
    required String uid,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) {
    throw Exception('reward service unavailable');
  }
}

class _AlreadyGrantedReward implements RewardRepository {
  @override
  Future<PointGrantResult> grantPoints({
    required String uid,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) async {
    return const PointGrantResult(pointsAwarded: 0, alreadyGranted: true);
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

Word _word(int index) {
  return Word(
    id: 'factory-word-$index',
    word: 'factory$index',
    phonetic: '/factory/',
    meaning: '工厂词 $index',
    definition: 'A generated test word $index',
    partOfSpeech: 'noun',
    exampleSentence: 'Factory word $index appears in a lesson.',
    exampleTranslation: '工厂词 $index 出现在课程中。',
    imageCue: '🏭',
    difficulty: 'Medium',
    tags: const ['test'],
  );
}

WordBook _book(String id, String title) {
  return WordBook(
    id: id,
    title: title,
    category: 'exam',
    examType: title,
    coverUrl: '',
    totalWords: 1,
    includedWords: 1,
    description: '$title description',
    wordIds: const ['api-word-1'],
    createdAt: DateTime(2026, 6, 5),
    words: [_word(1)],
  );
}

String _todayDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
