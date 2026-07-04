import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/features/profile/settings_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

Widget _buildSettingsApp(AppState state) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (c, s) => const SettingsScreen()),
    GoRoute(path: '/settings/study-plan', builder: (c, s) => const Scaffold()),
    GoRoute(path: '/settings/reminder', builder: (c, s) => const Scaffold()),
    GoRoute(path: '/profile', builder: (c, s) => const Scaffold()),
    GoRoute(path: '/profile/privacy', builder: (c, s) => const Scaffold()),
    GoRoute(path: '/profile/data', builder: (c, s) => const Scaffold()),
  ]);
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(() => _FakeAppController(state)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

void main() {
  group('Daily Reminder subtitle — Bug H', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('enabled reminder shows "Daily · 20:00", not "day 20:00"',
        (tester) async {
      final state = AppState.initial().copyWith(
        isBootstrapped: true,
        reminderSettings: const DailyReminderSettings(
          enabled: true,
          hour: 20,
          minute: 0,
        ),
      );
      await tester.pumpWidget(_buildSettingsApp(state));
      await tester.pump();

      expect(find.text('Daily · 20:00'), findsOneWidget);
      expect(find.text('day 20:00'), findsNothing);
    });
  });
}
