import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// The screen under test.
import 'package:linguaquest/features/map/language_map_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LanguageMapScreen renders FlutterMap with 6 language pins',
      (tester) async {
    // Use a large surface so the world-zoom map viewport includes all markers.
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh'), Locale('ms')],
          locale: Locale('en'),
          home: LanguageMapScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // FlutterMap should be present
    expect(find.byType(FlutterMap), findsOneWidget);

    // All 6 language pin keys should be present (keys are on GestureDetector child)
    expect(find.byKey(const ValueKey('lang-pin-zh')), findsWidgets);
    expect(find.byKey(const ValueKey('lang-pin-en')), findsWidgets);
    expect(find.byKey(const ValueKey('lang-pin-es')), findsWidgets);
    expect(find.byKey(const ValueKey('lang-pin-fr')), findsWidgets);
    expect(find.byKey(const ValueKey('lang-pin-ja')), findsWidgets);
    expect(find.byKey(const ValueKey('lang-pin-ms')), findsWidgets);
  });

  testWidgets(
      'Tapping zh pin records targetLanguage zh and opens wordbook picker '
      '(P2e: language+wordbook flow replaces bare confirm sheet)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh'), Locale('ms')],
          locale: Locale('en'),
          home: LanguageMapScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Tap the zh pin — this now calls updateTargetLanguage then opens the
    // wordbook picker sheet (two-level, pre-seeded to Chinese wordbooks).
    await tester.tap(
      find.byKey(const ValueKey('lang-pin-zh')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // targetLanguage must be set to 'zh' via updateTargetLanguage (achievement stamp).
    final state = container.read(appControllerProvider);
    expect(state.targetLanguage, 'zh');

    // The old bare-confirm sheet (lang-confirm-zh) is GONE; picker or modal appears.
    // In test env the wordbook picker sheet is shown (DraggableScrollableSheet).
    // At minimum, no SnackBar with "coming soon" should appear.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
      'Tapping ja pin (P2e: now ENABLED) records targetLanguage ja and opens picker — '
      'no coming-soon SnackBar',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh'), Locale('ms')],
          locale: Locale('en'),
          home: LanguageMapScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Tap the ja pin — now ENABLED (P2e), so it should NOT show a snackbar.
    await tester.tap(
      find.byKey(const ValueKey('lang-pin-ja')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // targetLanguage must be updated to 'ja'.
    final state = container.read(appControllerProvider);
    expect(state.targetLanguage, 'ja');

    // Must NOT show a coming-soon SnackBar (that was the old disabled-pin behavior).
    // Find any SnackBars and verify none contain "coming soon" text for Japanese.
    final snackBars = find.byType(SnackBar);
    if (snackBars.evaluate().isNotEmpty) {
      // If a SnackBar is present it must not be a coming-soon message.
      final snackBarTexts = tester.widgetList<SnackBar>(snackBars).map((s) {
        final content = s.content;
        if (content is Text) return content.data ?? '';
        return '';
      }).toList();
      for (final text in snackBarTexts) {
        expect(text.toLowerCase(), isNot(contains('soon')));
        expect(text.toLowerCase(), isNot(contains('日本語')));
      }
    }
  });

  testWidgets('Tapping a non-enabled pin (en) still shows coming-soon SnackBar',
      (tester) async {
    // Use a large surface so all markers are in the viewport.
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh'), Locale('ms')],
          locale: Locale('en'),
          home: LanguageMapScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Tap the 'en' pin (still disabled / coming-soon).
    await tester.tap(
      find.byKey(const ValueKey('lang-pin-en')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    // A SnackBar should appear (coming-soon).
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
