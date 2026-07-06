import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/features/quests/progress_analytics_screen.dart';
import 'package:linguaquest/features/reading/reading_list_screen.dart';
import 'package:linguaquest/features/shell/app_shell.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Dark Mode — app wiring', () {
    testWidgets('MaterialApp honors ThemeMode.dark when state is dark', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'linguaquest.themeMode': 'dark',
      });

      await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });

    testWidgets('MaterialApp honors ThemeMode.light when state is light', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'linguaquest.themeMode': 'light',
      });

      await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);
    });

    testWidgets('MaterialApp has a non-null darkTheme', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.darkTheme, isNotNull);
    });
  });

  group('Dark Mode — analytics screen smoke', () {
    testWidgets('ProgressAnalyticsScreen renders without exception in dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const ProgressAnalyticsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('Dark Mode — reading screens smoke', () {
    testWidgets('ReadingListScreen renders without exception in dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const ReadingListScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Dark Mode — app shell', () {
    testWidgets('shell background follows the dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const AppShell(selectedIndex: 0, child: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();

      final shellScaffold = tester
          .widgetList<Scaffold>(find.byType(Scaffold))
          .firstWhere((s) => s.bottomNavigationBar != null);
      expect(shellScaffold.backgroundColor, isNot(AppTheme.paper));
      expect(
        shellScaffold.backgroundColor,
        AppTheme.dark().scaffoldBackgroundColor,
      );
    });
  });
}
