import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/features/shell/app_shell.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'AppShell scaffold paints the porcelain background explicitly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          home: const AppShell(
            selectedIndex: 0,
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.paper);
    },
  );
}
