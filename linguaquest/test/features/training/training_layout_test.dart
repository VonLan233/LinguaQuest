import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/section_header.dart';
import 'package:linguaquest/features/training/training_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

void main() {
  testWidgets('training screen has no section headers (all flat)', (
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
    expect(find.byType(SectionHeader), findsNothing);
    // 6 训练项仍在
    for (final t in [
      'Campus Sprint',
      'Speed Game',
      'Last One Standing',
      'Spelling',
      'Passage Cloze',
      'Listening Sprint',
    ]) {
      expect(find.textContaining(t), findsWidgets, reason: t);
    }
  });
}
