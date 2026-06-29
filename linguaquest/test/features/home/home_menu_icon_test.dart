import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/features/home/home_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

void main() {
  testWidgets('home menu (hamburger) icon uses theme onSurface color', (
    tester,
  ) async {
    final state = AppState.initial().copyWith(isBootstrapped: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(() => _FakeAppController(state)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: const HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    final iconWidget = tester.widget<Icon>(find.byIcon(AppIcons.menu));
    final ctx = tester.element(find.byIcon(AppIcons.menu));
    expect(iconWidget.color, Theme.of(ctx).colorScheme.onSurface);
  });
}
