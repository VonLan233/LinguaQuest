import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/language_wordbook_picker.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WordBook _fakeBook(String id, {String language = 'zh'}) {
  final now = DateTime.now().toUtc();
  return WordBook(
    id: id,
    title: id.toUpperCase(),
    category: 'exam',
    examType: id,
    coverUrl: '',
    totalWords: 10,
    includedWords: 10,
    description: '',
    wordIds: const [],
    createdAt: now,
    words: const [],
    language: language,
  );
}

/// Fake notifier that records calls to [switchWordBook] without touching prefs.
class _FakeNotifier extends AppController {
  _FakeNotifier(this._state);

  final AppState _state;
  final List<String> switchCalls = [];

  @override
  AppState build() => _state;

  @override
  Future<bool> switchWordBook(String wordBookId) async {
    switchCalls.add(wordBookId);
    return true;
  }
}

Widget _harness({
  required AppState state,
  void Function(_FakeNotifier notifier)? capture,
}) {
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(() {
        final notifier = _FakeNotifier(state);
        capture?.call(notifier);
        return notifier;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showLanguageWordbookPicker(ctx),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

AppState _zhState({String current = 'hsk1', int books = 6}) {
  return AppState.initial().copyWith(
    wordBooks: [
      for (var i = 1; i <= books; i++) _fakeBook('hsk$i'),
    ],
    currentWordBookId: current,
    currentLanguage: 'zh',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LanguageWordbookPicker', () {
    testWidgets('shows Chinese (active) and Japanese (coming-soon)',
        (tester) async {
      await tester.pumpWidget(_harness(state: _zhState(books: 3)));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Chinese (中文)'), findsOneWidget);
      expect(find.text('Japanese (日本語)'), findsOneWidget);
      // Japanese is the only coming-soon language → its pill is present.
      expect(find.text('Coming Soon'), findsWidgets);
    });

    testWidgets('selecting Chinese language shows hsk wordbooks',
        (tester) async {
      await tester.pumpWidget(_harness(state: _zhState(books: 6)));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chinese (中文)'));
      await tester.pumpAndSettle();

      expect(find.text('HSK1'), findsOneWidget);
      // HSK6 sits below the fold of the bottom sheet — scroll it into view.
      await tester.dragUntilVisible(
        find.text('HSK6'),
        find.byType(ListView),
        const Offset(0, -120),
      );
      expect(find.text('HSK6'), findsOneWidget);
    });

    testWidgets('Japanese shows coming-soon, not a wordbook list',
        (tester) async {
      await tester.pumpWidget(_harness(state: _zhState(books: 6)));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Japanese row is non-selectable (coming-soon) — tapping it must not
      // navigate to a wordbook list.
      await tester.tap(find.text('Japanese (日本語)'));
      await tester.pumpAndSettle();

      // No HSK books appear; still on the language list (Chinese visible).
      expect(find.text('HSK1'), findsNothing);
      expect(find.text('Chinese (中文)'), findsOneWidget);
      expect(find.text('Coming Soon'), findsWidgets);
    });

    testWidgets(
        'selecting a wordbook calls switchWordBook (no other-scope wipe)',
        (tester) async {
      late _FakeNotifier notifier;
      await tester.pumpWidget(_harness(
        state: _zhState(books: 2),
        capture: (n) => notifier = n,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chinese (中文)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('HSK2'));
      await tester.pumpAndSettle();

      // The picker delegates to the P2b scope-switch method; it does not
      // mutate any other scope's keys itself.
      expect(notifier.switchCalls, contains('hsk2'));
    });
  });
}
