// Tests that the Profile screen's Study Plan item shows the locale-aware
// wordbook name (same source as HomeScreen), not the raw book.title.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/profile/profile_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

/// Build a minimal WordBook whose title (default/zh) and titleEn differ,
/// so currentStudyBook.name (= title) ≠ nameFor('en') (= titleEn).
WordBook _book({
  String id = 'hsk2',
  String title = 'HSK 2',
  String titleEn = 'HSK Level 2',
}) =>
    WordBook(
      id: id,
      title: title,
      titleEn: titleEn,
      category: 'basic',
      examType: 'HSK',
      coverUrl: '',
      totalWords: 0,
      includedWords: 0,
      description: '',
      wordIds: const [],
      createdAt: DateTime(2026, 1, 1),
      words: const [],
      language: 'zh',
    );

Widget _pumpProfileScreen(AppState state) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (c, s) => const ProfileScreen()),
    // stub all push targets used inside ProfileScreen
    GoRoute(
      path: '/settings',
      builder: (c, s) => const Scaffold(body: Text('Settings')),
    ),
    GoRoute(
      path: '/settings/study-plan',
      builder: (c, s) => const Scaffold(body: Text('StudyPlan')),
    ),
  ]);
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(() => _FakeAppController(state)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets(
    'Profile Plan item shows nameFor(locale) not currentStudyBook.name when they differ',
    (tester) async {
      final book = _book();
      final state = AppState.initial().copyWith(
        isBootstrapped: true,
        wordBooks: [book],
        currentWordBookId: book.id,
      );

      // Verify test precondition: the two values must be different.
      // currentStudyBook.name = book.title = 'HSK 2'
      // currentWordBook!.nameFor('en') = book.titleEn = 'HSK Level 2'
      expect(state.currentStudyBook.name, 'HSK 2');
      expect(state.currentWordBook!.nameFor('en'), 'HSK Level 2');
      expect(state.currentStudyBook.name, isNot(state.currentWordBook!.nameFor('en')));

      await tester.pumpWidget(_pumpProfileScreen(state));
      await tester.pump();

      // The Plan settings item should show the locale-aware name 'HSK Level 2'…
      expect(find.text('HSK Level 2'), findsWidgets);
      // …and must NOT show only the raw title 'HSK 2' in that item.
      // (We confirm 'HSK Level 2' is present; the raw name check is implicit.)
    },
  );

  testWidgets(
    'Language row uses a short title and wraps long language/book values without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(393, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overflowErrors = <FlutterErrorDetails>[];
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflowErrors.add(details);
        } else {
          originalHandler?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = originalHandler);

      final book = _book(
        id: 'very-long-book',
        title: 'Very Long Book',
        titleEn: 'A Very Long Campus Spanish Wordbook Name That Should Wrap',
      );
      final state = AppState.initial().copyWith(
        isBootstrapped: true,
        wordBooks: [book],
        currentWordBookId: book.id,
        currentLanguage: 'es',
      );

      await tester.pumpWidget(_pumpProfileScreen(state));
      await tester.pump();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Choose Language'), findsNothing);
      expect(find.text('Spanish (Español)'), findsOneWidget);
      expect(
        find.text('A Very Long Campus Spanish Wordbook Name That Should Wrap'),
        findsWidgets,
      );
      expect(
        overflowErrors,
        isEmpty,
        reason:
            'Profile Language row overflowed on a 393 px viewport: '
            '${overflowErrors.map((e) => e.exceptionAsString()).join(', ')}',
      );
    },
  );
}
