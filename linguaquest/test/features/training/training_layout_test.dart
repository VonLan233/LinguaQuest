import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/features/training/training_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

void main() {
  testWidgets('Campus Sprint section appears above Timed Tests', (
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
          home: const TrainingScreen(),
        ),
      ),
    );
    await tester.pump();

    final campus = find.text('Campus Sprint');
    final timed = find.text('Timed Tests');
    expect(campus, findsWidgets);
    expect(timed, findsOneWidget);
    final campusY = tester.getTopLeft(campus.first).dy;
    final timedY = tester.getTopLeft(timed).dy;
    expect(campusY, lessThan(timedY)); // Campus Sprint 在 Timed Tests 之上
  });
}
