import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/features/reading/article_reader_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_article_repository.dart';

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
        ArticleParagraph(
          index: 1,
          text: '然后吃早饭。',
          translation: 'Then I eat breakfast.',
          reading: 'rán hòu chī zǎo fàn.',
        ),
      ],
      vocab: const [
        ArticleVocabRef(
          surface: '起来',
          reading: 'qǐ lái',
          meaning: 'to get up',
          role: 'key',
        ),
      ],
      comprehension: const [],
      estimatedMinutes: 3,
      createdAt: DateTime(2026, 6, 27),
    );

Article _jaArticle() => Article(
      id: 'ja_n5_life_001',
      language: 'ja',
      level: 'jlpt_n5',
      examLevel: 5,
      theme: 'life',
      title: 'わたしの あさ',
      titleTranslation: 'My Morning',
      paragraphs: const [
        ArticleParagraph(
          index: 0,
          text: 'わたしは あさ おきます。',
          translation: 'I wake up in the morning.',
          reading: 'watashi wa asa okimasu.',
        ),
      ],
      vocab: const [
        ArticleVocabRef(
          surface: 'おきます',
          reading: 'okimasu',
          meaning: 'to wake up',
          role: 'key',
        ),
      ],
      comprehension: const [],
      estimatedMinutes: 3,
      createdAt: DateTime(2026, 6, 27),
    );

Widget _harness(FakeArticleRepository repo, String id) {
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
      home: ArticleReaderScreen(articleId: id),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the article paragraphs', (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    expect(find.textContaining('每天'), findsOneWidget);
    expect(find.textContaining('早饭'), findsOneWidget);
  });

  testWidgets('translation toggle shows/hides translations', (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    // Default: translation visible.
    expect(find.text('Then I eat breakfast.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-toggle-translation')));
    await tester.pumpAndSettle();

    expect(find.text('Then I eat breakfast.'), findsNothing);
  });

  testWidgets('reading toggle shows/hides pinyin (zh)', (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    expect(find.text('rán hòu chī zǎo fàn.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-toggle-reading')));
    await tester.pumpAndSettle();

    expect(find.text('rán hòu chī zǎo fàn.'), findsNothing);
  });

  testWidgets('reading toggle shows romaji for ja article', (tester) async {
    final repo = FakeArticleRepository([_jaArticle()]);
    await tester.pumpWidget(_harness(repo, 'ja_n5_life_001'));
    await tester.pumpAndSettle();

    expect(find.text('watashi wa asa okimasu.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reading-toggle-reading')));
    await tester.pumpAndSettle();

    expect(find.text('watashi wa asa okimasu.'), findsNothing);
  });

  testWidgets('tapping a vocab surface shows its meaning', (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    // Tap the rendered "起来" vocab span via its gesture recognizer.
    final richText = tester.widgetList<RichText>(find.byType(RichText));
    var tapped = false;
    for (final rt in richText) {
      rt.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text == '起来' &&
            span.recognizer is TapGestureRecognizer) {
          (span.recognizer as TapGestureRecognizer).onTap?.call();
          tapped = true;
          return false;
        }
        return true;
      });
      if (tapped) break;
    }
    expect(tapped, isTrue, reason: 'expected a tappable 起来 span');

    await tester.pumpAndSettle();
    expect(find.text('to get up'), findsOneWidget);
  });

  testWidgets('highlighted vocab renders as a tappable span (P3d)',
      (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    // The curated key word "起来" is rendered as a span with a tap recognizer.
    var hasHighlightSpan = false;
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text == '起来' &&
            span.recognizer != null) {
          hasHighlightSpan = true;
          return false;
        }
        return true;
      });
      if (hasHighlightSpan) break;
    }
    expect(hasHighlightSpan, isTrue,
        reason: 'expected 起来 highlighted + tappable');
  });

  testWidgets('highlight toggle off → plain text, no tappable spans (P3d)',
      (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reading-toggle-highlight')));
    await tester.pumpAndSettle();

    // With highlight off, no "起来" span carries a tap recognizer.
    var hasRecognizer = false;
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan &&
            (span.text?.contains('起来') ?? false) &&
            span.recognizer != null) {
          hasRecognizer = true;
          return false;
        }
        return true;
      });
    }
    expect(hasRecognizer, isFalse,
        reason: 'highlight off should render plain, untappable text');
    // Paragraph text still present.
    expect(find.textContaining('起来'), findsWidgets);
  });

  testWidgets('reading progress is saved on render', (tester) async {
    final repo = FakeArticleRepository([_zhArticle()]);
    await tester.pumpWidget(_harness(repo, 'zh_hsk1_life_001'));
    await tester.pumpAndSettle();

    expect(repo.savedProgress, isNotEmpty);
    // Reached the last paragraph (index 1 of 2) → completed.
    expect(repo.savedProgress.last.articleId, 'zh_hsk1_life_001');
    expect(repo.savedProgress.last.completed, isTrue);
  });
}
