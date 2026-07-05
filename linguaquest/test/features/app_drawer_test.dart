import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/shell/app_drawer.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('AppDrawer lists Choose Language and About entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(drawer: const AppDrawer(), body: const SizedBox()),
        onGenerateRoute: (_) => null,
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Choose Language'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  // Task 7.4: the Choose Language entry must go through l10n, not a hardcoded
  // English literal (the literal caused an untranslated / dark-mode wrap issue).
  test('AppDrawer Choose Language uses l10n.pickerChooseLanguage', () {
    final src = File('lib/features/shell/app_drawer.dart').readAsStringSync();
    expect(src.contains('l10n.pickerChooseLanguage'), isTrue);
    expect(src.contains("'Choose Language'"), isFalse);
  });

  test(
    'AppDrawer entries push so Android back returns to the original page',
    () {
      final src = File('lib/features/shell/app_drawer.dart').readAsStringSync();
      expect(src.contains('context.push(route)'), isTrue);
      expect(src.contains('context.go(route)'), isFalse);
    },
  );
}
