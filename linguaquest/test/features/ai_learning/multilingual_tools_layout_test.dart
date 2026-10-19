import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/features/ai_learning/ai_chat_screen.dart';
import 'package:linguaquest/features/ai_learning/ai_cloze_screen.dart';
import 'package:linguaquest/features/ai_learning/ai_confusable_words_screen.dart';
import 'package:linguaquest/features/ai_learning/ai_sentence_analysis_screen.dart';
import 'package:linguaquest/features/ai_learning/ai_sentence_gen_screen.dart';
import 'package:linguaquest/features/ai_learning/ai_writing_review_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in ['zh', 'ja', 'en']) {
    testWidgets('$locale AI tools have localized controls at 360px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      final cases = <(Widget, String, String)>[
        (const AiChatScreen(word: '猫'), l10n.aiUiAiQA, l10n.aiUiAskAQuestion),
        (
          const AiSentenceAnalysisScreen(),
          l10n.aiUiAiSentenceAnalysis,
          l10n.aiUiEnterASentenceToAnalyze,
        ),
        (
          const AiClozeScreen(),
          l10n.aiUiAiClozeTest,
          l10n.aiUiEnterAWordForClozeTest,
        ),
        (
          const AiConfusableWordsScreen(),
          l10n.aiUiConfusableWords,
          l10n.aiUiEnterAWordToCompareWithItsLookAlikes,
        ),
        (
          const AiSentenceGenScreen(),
          l10n.aiUiSentenceGeneration,
          l10n.aiUiEnterAWordOrASentence,
        ),
        (
          const AiWritingReviewScreen(),
          l10n.aiUiAiWritingReview,
          l10n.aiUiSubmitForReview,
        ),
      ];
      for (final (screen, title, label) in cases) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: Locale(locale),
              theme: AppTheme.dark(),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: screen,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets);
        expect(find.text(label), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
