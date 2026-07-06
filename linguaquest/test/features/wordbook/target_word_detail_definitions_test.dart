// T10 — TargetWordDetailScreen definition sections.
//
// The app teaches Chinese (HSK); the localized "Chinese definitions" list only
// duplicates the English meanings. A non-CJK word (e.g. the English starter
// wordbook) must therefore NOT render the redundant Chinese-definition block
// (nor the bilingual header) — only the English (+ Malay) definitions remain.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/utils/text_language.dart';
import 'package:linguaquest/features/wordbook/target_word_detail_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'non-CJK word detail drops the redundant Chinese-definition block',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();

      // Pick a real non-CJK word carrying both a (Chinese) meaning and an
      // English definition, so the old code path would have rendered a
      // "中文释义" list.
      final word = container
          .read(appControllerProvider)
          .wordBooks
          .expand((book) => book.words)
          .firstWhere(
            (item) =>
                !containsCjkText(item.word) &&
                item.meaning.trim().isNotEmpty &&
                (item.englishDefinitions.isNotEmpty ||
                    item.definition.trim().isNotEmpty),
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

      // No redundant Chinese meanings and no bilingual header.
      expect(find.text('中文释义'), findsNothing);
      expect(find.text('中英释义'), findsNothing);
      // English definitions still shown.
      expect(find.text('英文释义'), findsOneWidget);
    },
  );
}
