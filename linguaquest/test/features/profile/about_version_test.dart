import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/features/profile/about_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'LinguaQuest',
      packageName: 'com.example.linguaquest',
      version: '1.0.3',
      buildNumber: '3',
      buildSignature: '',
    );
  });

  testWidgets('AboutScreen 显示 package_info_plus 动态版本号', (tester) async {
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

    expect(find.text('LinguaQuest · Version 1.0.3'), findsOneWidget);
    expect(find.text('LinguaQuest · Version 1.0.0'), findsNothing);
  });
}
