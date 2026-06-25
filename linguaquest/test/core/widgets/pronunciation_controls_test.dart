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
    await tester.pumpWidget(_wrap(
      const PronunciationControls(word: '你好'),
    ));
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsNothing);
  });
}
