import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/features/auth/goal_setup_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bug 2 (task 2.1): "daily word count" and "deadline plan" used to coexist on
// the same page while sharing one saved plan (deadline silently overriding the
// daily goal). They must now be a mutually-exclusive single choice: only the
// selected mode's input is shown.
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(),
          home: const GoalSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The plan section sits below the fold in the ListView; bring the mode
    // selector into view before interacting with it.
    await tester.scrollUntilVisible(
      find.text('Plan by Deadline'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('daily mode shows word choices and hides deadline picker', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Daily mode is the default: word-count choices are built, and the
    // deadline picker is not in the tree at all.
    expect(find.byKey(const ValueKey('choice-10')), findsOneWidget);
    expect(find.text('Pick Date'), findsNothing);
  });

  testWidgets('switching to deadline mode hides word choices', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Plan by Deadline'));
    await tester.pumpAndSettle();

    // Now only the deadline input exists; the daily word choices are gone.
    expect(find.byKey(const ValueKey('choice-10')), findsNothing);
    expect(find.text('Pick Date'), findsOneWidget);
  });
}
