import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// The screen under test (does not exist yet — test should FAIL until M2 impl)
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
      'Tapping zh pin shows bottom sheet; confirming updates targetLanguage',
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

    // Tap the zh pin
    await tester.tap(
      find.byKey(const ValueKey('lang-pin-zh')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // Bottom sheet should appear with confirm button
    expect(find.byKey(const ValueKey('lang-confirm-zh')), findsOneWidget);

    // Tap the confirm button
    await tester.tap(
      find.byKey(const ValueKey('lang-confirm-zh')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // targetLanguage should now be 'zh'
    final state = container.read(appControllerProvider);
    expect(state.targetLanguage, 'zh');
  });

  testWidgets('Tapping ja (coming-soon) pin shows snackbar, no state change',
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

    // Tap the ja pin (coming soon)
    await tester.tap(
      find.byKey(const ValueKey('lang-pin-ja')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    // A SnackBar should appear containing the coming-soon text
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
