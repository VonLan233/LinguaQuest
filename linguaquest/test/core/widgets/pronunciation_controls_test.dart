import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/pronunciation_controls.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('tapping pronunciation shows NO SnackBar', (tester) async {
    await tester.pumpWidget(_wrap(const PronunciationControls(word: '你好')));
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('kana-only Japanese word renders single Audio button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const PronunciationControls(word: 'こんにちは', language: 'ja')),
    );
    await tester.pump();
    // Single-button layout: native audio only, no UK accent or 0.5x slow button.
    expect(find.byKey(const ValueKey('pronunciation-uk')), findsNothing);
    expect(find.byKey(const ValueKey('pronunciation-us')), findsOneWidget);
    expect(find.byKey(const ValueKey('pronunciation-slow')), findsNothing);
    expect(find.text('0.5×'), findsNothing);
  });

  testWidgets('English word renders single Audio button (no UK/US pair)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const PronunciationControls(word: 'hello')));
    await tester.pump();
    // Collapsed to one Audio button: no UK/US accent split and no 0.5x button.
    expect(find.byKey(const ValueKey('pronunciation-uk')), findsNothing);
    expect(find.byKey(const ValueKey('pronunciation-us')), findsOneWidget);
    expect(find.byKey(const ValueKey('pronunciation-slow')), findsNothing);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('0.5×'), findsNothing);
    expect(find.text('英音'), findsNothing);
    expect(find.text('美音'), findsNothing);
  });
}
