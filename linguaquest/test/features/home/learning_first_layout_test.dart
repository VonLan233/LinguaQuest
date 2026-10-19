import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/features/home/home_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _Controller extends AppController {
  _Controller(this.initial);
  final AppState initial;
  @override
  AppState build() => initial;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in ['zh', 'ja', 'en']) {
      for (final language in ['zh', 'ja', 'en']) {
        testWidgets(
          '$locale UI / $language book $brightness home fits 360px and keeps encouragement on one line',
          (tester) async {
            tester.view.physicalSize = const Size(360, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final book = WordBook.fromJson(
              jsonDecode(
                    File(
                      'lib/assets/data/wordbook_${language}_starter.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>,
            );
            final state = AppState.initial().copyWith(
              user: UserProfile.demo(),
              wordBooks: [book],
              currentWordBookId: book.id,
              currentLanguage: language,
              lessons: lessonsFromWordBook(book),
            );
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  appControllerProvider.overrideWith(() => _Controller(state)),
                ],
                child: MaterialApp(
                  locale: Locale(locale),
                  theme: brightness == Brightness.light
                      ? AppTheme.light()
                      : AppTheme.dark(),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  home: const Scaffold(body: SafeArea(child: HomeScreen())),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final quote = tester.widget<Text>(
              find.byKey(const ValueKey('daily-encouragement')),
            );
            expect(quote.maxLines, 1);
            expect(quote.softWrap, isFalse);
            expect(find.byKey(const ValueKey('home-continue')), findsOneWidget);
            expect(
              tester
                  .getBottomRight(find.byKey(const ValueKey('home-continue')))
                  .dy,
              lessThan(724),
            );
          },
        );
      }
    }
  }
}
