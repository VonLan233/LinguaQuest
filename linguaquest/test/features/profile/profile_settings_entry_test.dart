import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/features/profile/profile_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

void main() {
  testWidgets('Me/Profile screen exposes a Settings entry routing to /settings',
      (tester) async {
    String? pushed;
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const ProfileScreen()),
      GoRoute(
          path: '/settings',
          builder: (c, s) {
            pushed = '/settings';
            return const Scaffold(body: Text('SETTINGS'));
          }),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appControllerProvider.overrideWith(
            () => _FakeAppController(AppState.initial().copyWith(isBootstrapped: true))),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ));
    await tester.pump();
    expect(find.text('Settings'), findsWidgets);
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(pushed, '/settings');
  });
}
