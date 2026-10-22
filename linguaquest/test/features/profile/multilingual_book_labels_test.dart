import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/utils/wordbook_languages.dart';
import 'package:linguaquest/core/widgets/language_wordbook_picker.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/features/profile/profile_screen.dart';
import 'package:linguaquest/features/profile/settings_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _Controller extends AppController {
  _Controller(this.initial);
  final AppState initial;
  @override
  AppState build() => initial;
}

WordBook _book(String id) => WordBook.fromJson(
  jsonDecode(File('lib/assets/data/wordbook_$id.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  test(
    'starter coverage is complete and legacy books do not claim Japanese',
    () {
      for (final language in ['zh', 'ja', 'en']) {
        expect(wordbookExplanationLanguages(_book('${language}_starter')), [
          'zh',
          'ja',
          'en',
        ]);
      }
      expect(wordbookExplanationLanguages(_book('hsk1')), contains('en'));
      expect(
        wordbookExplanationLanguages(_book('jlpt_n5')),
        isNot(contains('ja')),
      );
    },
  );

  for (final locale in ['zh', 'ja', 'en']) {
    for (final language in ['zh', 'ja', 'en']) {
      testWidgets(
        '$locale UI / $language book labels fit 360px with larger text',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final book = _book('${language}_starter');
          final state = AppState.initial().copyWith(
            user: UserProfile.demo().copyWith(targetExam: book.id),
            wordBooks: [book],
            currentWordBookId: book.id,
            currentLanguage: language,
          );
          for (final screen in [
            const ProfileScreen(),
            const SettingsScreen(),
          ]) {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  appControllerProvider.overrideWith(() => _Controller(state)),
                ],
                child: MaterialApp(
                  theme: AppTheme.light(),
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(1.3)),
                    child: child!,
                  ),
                  home: Scaffold(body: screen),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.textContaining(book.id), findsNothing);
            expect(find.textContaining(book.nameFor(locale)), findsWidgets);
          }
        },
      );
    }
  }

  testWidgets('language names follow the explanation locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) =>
              Text(languageLabel('en', AppLocalizations.of(context))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('英语'), findsOneWidget);
  });
}
