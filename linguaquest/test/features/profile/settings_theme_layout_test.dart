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
  group('_ThemeSettingCard layout — RadioListTile replaces SegmentedButton', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders 3 RadioListTile<ThemeMode>, no SegmentedButton',
        (tester) async {
      final state = AppState.initial().copyWith(
        isBootstrapped: true,
        themeMode: ThemeMode.system,
      );
      await tester.pumpWidget(_buildSettingsApp(state));
      await tester.pump();
      // _ThemeSettingCard may be off-screen in ListView — scroll to reveal it.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
      expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    });

    testWidgets('shows Follow System, Light and Dark labels', (tester) async {
      final state = AppState.initial().copyWith(
        isBootstrapped: true,
        themeMode: ThemeMode.system,
      );
      await tester.pumpWidget(_buildSettingsApp(state));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(find.text('Follow System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('tapping Light radio tile triggers onChanged with ThemeMode.light',
        (tester) async {
      ThemeMode? received;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: RadioGroup<ThemeMode>(
                groupValue: ThemeMode.system,
                onChanged: (m) {
                  if (m != null) received = m;
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: const Text('Follow System'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: const Text('Light'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: const Text('Dark'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Light'));
      await tester.pump();

      expect(received, ThemeMode.light);
    });
  });
}
