// UI Regression smoke tests.
//
// These tests verify the app boots without crashing and key widgets render
// under various viewport constraints. No golden images are used — only
// structural / text assertions via flutter_test.
//
// Run independently:
//   flutter test test/ui_regression_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App boot smoke tests', () {
    testWidgets(
      'app starts without crashing when no session exists',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // The brand name is locale-independent (same in all ARB files).
        expect(find.text('LinguaQuest'), findsWidgets);

        // MaterialApp.router is the root widget — confirms the widget tree built.
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'onboarding screen renders a Scrollable and at least one button',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Onboarding page is scrollable.
        expect(find.byType(Scrollable), findsWidgets);

        // At least one tappable ElevatedButton / FilledButton / TextButton
        // is present (auth CTAs).
        expect(
          find.byWidgetPredicate((w) => w is ButtonStyleButton),
          findsWidgets,
        );
      },
    );
  });

  group('Narrow viewport (320 px) smoke tests', () {
    const narrowWidth = 320.0;
    const standardHeight = 640.0;

    Future<void> pumpNarrow(WidgetTester tester, Widget widget) async {
      tester.view.physicalSize = const Size(narrowWidth, standardHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets(
      'app does not crash on a 320 px wide viewport',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await pumpNarrow(
          tester,
          const ProviderScope(child: LinguaQuestApp()),
        );

        // If we reach here without an exception the test passes.
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'no text overflow errors on narrow viewport (onboarding)',
      (tester) async {
        // Collect overflow exceptions so we can report them; the test fails if
        // any are found.
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

        SharedPreferences.setMockInitialValues({});

        await pumpNarrow(
          tester,
          const ProviderScope(child: LinguaQuestApp()),
        );

        expect(
          overflowErrors,
          isEmpty,
          reason:
              'Text overflow detected on 320 px viewport: '
              '${overflowErrors.map((e) => e.exceptionAsString()).join(', ')}',
        );
      },
    );
  });
}
