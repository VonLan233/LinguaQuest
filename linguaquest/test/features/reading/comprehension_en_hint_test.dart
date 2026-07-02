import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/features/reading/reading_comprehension_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('题干显示英文提示', (tester) async {
    final article = Article.fromJson({
      'id': 'a1',
      'language': 'zh',
      'level': 'HSK 1',
      'theme': 'life',
      'title': 't',
      'titleTranslation': 'T',
      'paragraphs': [],
      'comprehension': [
        {
          'id': 'q1',
          'type': 'meaningChoice',
          'prompt': '老师姓什么？',
          'options': ['王', '李'],
          'answer': '王',
          'explanation': '文章说她叫王老师。',
          'promptEn': "What is the teacher's surname?",
          'optionsEn': ['Wang', 'Li'],
          'explanationEn': 'The text says she is Teacher Wang.',
        }
      ],
    });
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReadingComprehensionSheet(article: article)),
      ),
    ));
    await tester.pumpAndSettle();
    // 题干显示英文提示
    expect(find.text("What is the teacher's surname?"), findsOneWidget);
  });

  testWidgets('选项显示英文提示', (tester) async {
    final article = Article.fromJson({
      'id': 'a2',
      'language': 'zh',
      'level': 'HSK 1',
      'theme': 'life',
      'title': 't',
      'titleTranslation': 'T',
      'paragraphs': [],
      'comprehension': [
        {
          'id': 'q1',
          'type': 'meaningChoice',
          'prompt': '老师姓什么？',
          'options': ['王', '李'],
          'answer': '王',
          'explanation': '文章说她叫王老师。',
          'promptEn': "What is the teacher's surname?",
          'optionsEn': ['Wang', 'Li'],
          'explanationEn': 'The text says she is Teacher Wang.',
        }
      ],
    });
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReadingComprehensionSheet(article: article)),
      ),
    ));
    await tester.pumpAndSettle();
    // 选项显示「原文  ·  英文」格式
    expect(find.textContaining('王  ·  Wang'), findsOneWidget);
    expect(find.textContaining('李  ·  Li'), findsOneWidget);
  });
}
