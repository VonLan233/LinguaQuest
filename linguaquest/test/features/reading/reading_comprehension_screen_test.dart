import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/features/reading/reading_comprehension_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_article_repository.dart';

Word _word(String id) => Word(
      id: id,
      word: '词',
      phonetic: '',
      meaning: 'word',
      definition: 'word',
      partOfSpeech: '',
      exampleSentence: '',
      exampleTranslation: '',
      imageCue: '',
      difficulty: 'medium',
      tags: const [],
    );

QuizQuestion _q(String id, String prompt, String answer, List<String> opts) {
  return QuizQuestion(
    id: id,
    type: QuizQuestionType.meaningChoice,
    prompt: prompt,
    answer: answer,
    options: opts,
    explanation: 'because',
    word: _word(id),
  );
}

Article _article() => Article(
      id: 'zh_hsk1_life_001',
      language: 'zh',
      level: 'hsk1',
      examLevel: 1,
      theme: 'life',
      title: '我的一天',
      paragraphs: const [],
      vocab: const [],
      comprehension: [
        _q('q1', 'Q1?', 'morning', const ['morning', 'noon', 'night']),
        _q('q2', 'Q2?', 'true', const ['true', 'false']),
      ],
      createdAt: DateTime(2026, 6, 27),
    );

Widget _harness(FakeArticleRepository repo) {
  return ProviderScope(
    overrides: [
      articleRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: ReadingComprehensionSheet(article: _article())),
    ),
  );
}

void main() {
  setUp(() {
    final profile = UserProfile(
      uid: 'reader-1',
      name: 'Reader',
      email: 'r@lingua.quest',
      targetExam: 'HSK',
      level: 'Beginner',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
  });

  testWidgets('runs the flow, scores correctly, records a ReadingResult',
      (tester) async {
    final repo = FakeArticleRepository([_article()]);

    await tester.pumpWidget(_harness(repo));
    // Bootstrap the controller so a signed-in user exists for completeReading.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReadingComprehensionSheet)),
    );
    await container.read(appControllerProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Q1: answer correctly ("morning"), then advance.
    await tester.tap(find.text('morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reading-comprehension-next')));
    await tester.pumpAndSettle();

    // Q2: answer incorrectly ("false", correct is "true"), then finish.
    await tester.tap(find.text('false'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reading-comprehension-next')));
    await tester.pumpAndSettle();

    // Result summary: 1 / 2 correct.
    expect(
      find.text(l10n.readingComprehensionScore(1, 2)),
      findsOneWidget,
    );

    // A ReadingResult was recorded with the right score.
    expect(repo.savedResults, hasLength(1));
    final result = repo.savedResults.single;
    expect(result.articleId, 'zh_hsk1_life_001');
    expect(result.totalQuestions, 2);
    expect(result.correctAnswers, 1);
    expect(result.theme, 'life');
    // Article marked read.
    expect(repo.savedProgress.where((p) => p.completed), isNotEmpty);
  });

  testWidgets('empty comprehension shows the empty state', (tester) async {
    final repo = FakeArticleRepository([]);
    final emptyArticle = Article(
      id: 'a0',
      language: 'zh',
      level: 'hsk1',
      paragraphs: const [],
      vocab: const [],
      comprehension: const [],
      createdAt: DateTime(2026, 6, 27),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [articleRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ReadingComprehensionSheet(article: emptyArticle),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.readingComprehensionEmpty), findsOneWidget);
  });
}
