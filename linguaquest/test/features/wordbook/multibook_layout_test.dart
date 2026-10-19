import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/features/wordbook/offline_wordbooks_screen.dart';
import 'package:linguaquest/features/wordbook/wordbook_screen.dart';
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

Widget _host(AppState state, Widget screen) => ProviderScope(
  overrides: [appControllerProvider.overrideWith(() => _Controller(state))],
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: screen,
  ),
);

void main() {
  testWidgets('large books build visible vocabulary instead of every row', (
    tester,
  ) async {
    final book = _book('hsk6');
    final state = AppState.initial().copyWith(
      user: UserProfile.demo().copyWith(targetExam: 'HSK 6'),
      wordBooks: [book],
      currentWordBookId: book.id,
      lessons: lessonsFromWordBook(book),
    );
    await tester.pumpWidget(_host(state, const WordbookScreen()));
    await tester.pumpAndSettle();
    expect(book.words.length, greaterThan(2000));
    expect(find.text(book.words.last.word), findsNothing);
    await tester.scrollUntilVisible(
      find.text(book.words.first.word),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(book.words.first.word), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offline catalog filters without changing the active study book',
    (tester) async {
      final books = [
        for (final code in ['zh', 'ja', 'en']) _book('${code}_starter'),
      ];
      final state = AppState.initial().copyWith(
        wordBooks: books,
        currentWordBookId: 'ja_starter',
        currentLanguage: 'ja',
      );
      await tester.pumpWidget(_host(state, const OfflineWordbooksScreen()));
      await tester.pumpAndSettle();
      expect(find.text('All languages'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('offline-language-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('Everyday English'), findsOneWidget);
      expect(find.text('Everyday Japanese'), findsNothing);
      final context = tester.element(find.byType(OfflineWordbooksScreen));
      final stored = ProviderScope.containerOf(
        context,
      ).read(appControllerProvider);
      expect(stored.currentWordBookId, 'ja_starter');
      expect(stored.currentLanguage, 'ja');
      expect(tester.takeException(), isNull);
    },
  );
}
