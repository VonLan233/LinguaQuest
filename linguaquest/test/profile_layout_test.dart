import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/features/profile/profile_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'profile setting values align with their labels on the left grid',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(appControllerProvider.notifier).bootstrap();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final wordbookValue = tester.getTopLeft(find.text('490 words'));
      final wordbookTitle = tester.getTopLeft(find.text('Wordbook'));
      expect(wordbookValue.dx, closeTo(wordbookTitle.dx, .1));
      expect(wordbookValue.dy, greaterThan(wordbookTitle.dy));
      expect(find.byIcon(AppIcons.chevronRight), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
