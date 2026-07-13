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
    wordBooks: [for (var i = 1; i <= books; i++) _fakeBook('hsk$i')],
    currentWordBookId: current,
    currentLanguage: 'zh',
  );
}

AppState _bothLangState() {
  return AppState.initial().copyWith(
    wordBooks: [
      for (var i = 1; i <= 6; i++) _fakeBook('hsk$i', language: 'zh'),
      for (var n in [5, 4, 3, 2, 1]) _fakeBook('jlpt_n$n', language: 'ja'),
    ],
    currentWordBookId: 'hsk1',
    currentLanguage: 'zh',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LanguageWordbookPicker', () {
    testWidgets(
      'shows Chinese (active) and Japanese (active) in language list',
      (tester) async {
        await tester.pumpWidget(_harness(state: _bothLangState()));

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Chinese'), findsOneWidget);
        expect(find.text('Japanese'), findsOneWidget);
        // All six languages now ship books, so no "Coming Soon" pill renders.
        expect(find.text('Coming Soon'), findsNothing);
      },
    );

    testWidgets('level-1 list shows all six languages', (tester) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish (Español)'), findsOneWidget);
      expect(find.text('French (Français)'), findsOneWidget);
      expect(find.text('Malay (Bahasa Melayu)'), findsOneWidget);
      // All six languages are active now; no "Coming Soon" pill renders.
      expect(find.text('Coming Soon'), findsNothing);
    });

    test('languageLabelRaw resolves coming-soon language codes', () {
      expect(languageLabelRaw('en'), 'English');
      expect(languageLabelRaw('es'), 'Spanish (Español)');
      expect(languageLabelRaw('fr'), 'French (Français)');
      expect(languageLabelRaw('ms'), 'Malay (Bahasa Melayu)');
    });

    testWidgets('selecting Chinese language shows hsk wordbooks', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(state: _zhState(books: 6)));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chinese'));
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

    testWidgets('selecting Japanese shows jlpt wordbooks', (tester) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Japanese'));
      await tester.pumpAndSettle();

      // Should now show the JLPT book list.
      expect(find.text('JLPT_N5'), findsOneWidget);
    });

    testWidgets('language rows use Expanded (no Spacer) for aligned pills', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // 语言行不应再使用 Spacer（药丸靠 Expanded 推到右内边距，右缘对齐）。
      expect(find.byType(Spacer), findsNothing);
    });

    testWidgets(
      'selecting a wordbook calls switchWordBook (no other-scope wipe)',
      (tester) async {
        late _FakeNotifier notifier;
        await tester.pumpWidget(
          _harness(state: _zhState(books: 2), capture: (n) => notifier = n),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chinese'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('HSK2'));
        await tester.pumpAndSettle();

        // The picker delegates to the P2b scope-switch method; it does not
        // mutate any other scope's keys itself.
        expect(notifier.switchCalls, contains('hsk2'));
      },
    );

    testWidgets(
      'selecting a wordbook keeps the sheet open (immediate highlight)',
      (tester) async {
        _FakeNotifier? captured;
        await tester.pumpWidget(
          _harness(state: _zhState(books: 6), capture: (n) => captured = n),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chinese'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('HSK2'));
        await tester.pumpAndSettle();
        // 切换被调用，但 sheet 不再立即关闭（标题仍在）。
        expect(captured!.switchCalls, contains('hsk2'));
        expect(find.text('Choose Wordbook'), findsOneWidget);
      },
    );
  });
}
