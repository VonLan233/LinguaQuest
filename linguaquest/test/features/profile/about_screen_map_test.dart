import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:linguaquest/features/profile/about_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AboutScreen contains company locator map', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh'), Locale('ms')],
          locale: Locale('en'),
          home: AboutScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Scroll down to ensure the company map card is visible (it's below the fold)
    await tester.scrollUntilVisible(
      find.byType(FlutterMap),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    // FlutterMap should be present (company locator map)
    expect(find.byType(FlutterMap), findsOneWidget);

    // Company pin marker should be present
    expect(find.byKey(const ValueKey('company-pin')), findsOneWidget);

    // Company name 'LinguaQuest' should be visible
    expect(find.text('LinguaQuest'), findsWidgets);

    // No exception should be thrown
    expect(tester.takeException(), isNull);
  });
}
