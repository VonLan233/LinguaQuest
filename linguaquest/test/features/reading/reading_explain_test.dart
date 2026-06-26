// test/features/reading/reading_explain_test.dart
//
// P3f: widget tests for the per-paragraph AI explain affordance on the article
// reader. Covers the structured-result path and the error → retry → result path
// (reusing AiErrorCard), with aiRepositoryProvider overridden by a fake.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/widgets/ai_error_card.dart';
import 'package:linguaquest/data/models/ai_feature.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/data/repositories/ai_repository.dart';
import 'package:linguaquest/features/reading/article_reader_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_article_repository.dart';

// A structured stub matching the reading_explain shape.
Map<String, dynamic> _stub() => <String, dynamic>{
      'gist': 'The narrator describes a daily routine.',
      'keyWords': <Map<String, dynamic>>[
        {'word': '起来', 'reading': 'qǐ lái', 'meaning': 'to get up'},
      ],
      'grammarPoints': <String>['Subject + 每天 + verb expresses a habit.'],
      'structure': 'Subject (我) + adverb (每天) + verbs.',
      'translation': 'I get up and drink water every day.',
      'practice': <Map<String, dynamic>>[
        {
          'prompt': '"起来" means ___?',
          'answer': 'to get up',
          'options': <String>['to get up', 'to sleep', 'to eat', 'to run'],
        },
      ],
    };

/// Fake AiRepository whose explainParagraph throws [failTimes] times, then
/// returns the structured stub. Records the language it was called with.
class _FakeAiRepository implements AiRepository {
  _FakeAiRepository({this.failTimes = 0});

  final int failTimes;
  int explainCalls = 0;
  String? lastLanguage;

  @override
  Future<Map<String, dynamic>> explainParagraph({
    required String paragraph,
    required String language,
    String? level,
  }) async {
    explainCalls++;
    lastLanguage = language;
    if (explainCalls <= failTimes) {
      throw Exception('Simulated network failure');
    }
    return _stub();
  }

  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<AiHistoryEntry>> listHistory() async => [];

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  }) async =>
      throw UnimplementedError();
}

Article _zhArticle() => Article(
      id: 'zh_hsk1_life_001',
      language: 'zh',
      level: 'hsk1',
      examLevel: 1,
      theme: 'life',
      title: '我的一天',
      titleTranslation: 'My Day',
      paragraphs: const [
        ArticleParagraph(
          index: 0,
          text: '我每天起来喝水。',
          translation: 'I get up and drink water every day.',
          reading: 'wǒ měi tiān qǐ lái hē shuǐ.',
        ),
      ],
      vocab: const [],
      comprehension: const [],
      estimatedMinutes: 3,
      createdAt: DateTime(2026, 6, 27),
    );

Widget _harness(FakeArticleRepository repo, _FakeAiRepository ai) {
  return ProviderScope(
    overrides: [
      articleRepositoryProvider.overrideWithValue(repo),
      aiRepositoryProvider.overrideWithValue(ai),
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
      home: const ArticleReaderScreen(articleId: 'zh_hsk1_life_001'),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tapping Explain shows structured sections', (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    final ai = _FakeAiRepository();
    await tester.pumpWidget(_harness(repo, ai));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.byKey(const ValueKey('reading-explain-0')));
    await tester.pumpAndSettle();

    // Explain ran in the article's language.
    expect(ai.explainCalls, 1);
    expect(ai.lastLanguage, 'zh');

    // Structured result card with all section labels.
    expect(find.byKey(const ValueKey('reading-explain-result')), findsOneWidget);
    expect(find.text(l10n.readingExplainGist), findsOneWidget);
    expect(find.text(l10n.readingExplainKeyWords), findsOneWidget);
    expect(find.text(l10n.readingExplainGrammar), findsOneWidget);
    expect(find.text(l10n.readingExplainStructure), findsOneWidget);
    // "Translation" also appears as the toggle-bar chip label, so allow >= 1.
    expect(find.text(l10n.readingExplainTranslation), findsWidgets);
    expect(find.text(l10n.readingExplainPractice), findsOneWidget);

    // Stub content rendered.
    expect(find.textContaining('daily routine'), findsOneWidget);
  });

  testWidgets('error then retry shows AiErrorCard then the result',
      (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    final ai = _FakeAiRepository(failTimes: 1);
    await tester.pumpWidget(_harness(repo, ai));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // First explain fails → AiErrorCard shown, no result.
    await tester.tap(find.byKey(const ValueKey('reading-explain-0')));
    await tester.pumpAndSettle();

    expect(find.byType(AiErrorCard), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reading-explain-result')), findsNothing);

    // Tap Retry → second call succeeds → result shown, error gone.
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.byType(AiErrorCard), findsNothing);
    expect(
        find.byKey(const ValueKey('reading-explain-result')), findsOneWidget);
    expect(ai.explainCalls, 2);
  });
}
