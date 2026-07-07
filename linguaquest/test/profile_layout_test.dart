import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/features/profile/profile_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profile setting values align to the right edge', (tester) async {
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

    final wordbookRight = tester.getTopRight(find.text('490 words'));
    final customWordsRight = tester.getTopRight(find.text('0').last);
    final chevrons = find.byIcon(AppIcons.chevronRight);
    final wordbookChevronRight = tester.getTopRight(chevrons.at(2));
    final customWordsChevronRight = tester.getTopRight(chevrons.at(4));

    expect(
      (wordbookChevronRight.dx - wordbookRight.dx).abs(),
      lessThanOrEqualTo(56),
    );
    expect(
      (customWordsChevronRight.dx - customWordsRight.dx).abs(),
      lessThanOrEqualTo(56),
    );
  });
}
