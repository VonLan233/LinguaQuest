import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/app_button.dart';
import 'package:linguaquest/features/training/passage_cloze_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// Serves a fixed 2-blank cloze result so PassageClozeScreen reaches its
/// "questions loaded" state without hitting the network.
class _FakeClozeController extends AppController {
  _FakeClozeController(this._state);
  final AppState _state;

  @override
  AppState build() => _state;

  @override
  Future<Map<String, dynamic>> askAi({
    required String featureType,
    required String prompt,
    String? targetWord,
  }) async {
    return {
      'passage': '我每天____，也喜欢____。',
      'blanks': [
        {
          'index': 0,
          'answer': '读书',
          'options': ['读书', '跑步', '睡觉', '吃饭'],
        },
        {
          'index': 1,
          'answer': '运动',
          'options': ['运动', '画画', '唱歌', '游泳'],
        },
      ],
      'explanations': ['a', 'b'],
    };
  }
}

Widget _harness(AppState state) => ProviderScope(
      overrides: [
        appControllerProvider.overrideWith(() => _FakeClozeController(state)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const PassageClozeScreen(),
      ),
    );

void main() {
  testWidgets(
    'passage cloze shows question cards; bottom button does not fill the screen',
    (tester) async {
      await tester.pumpWidget(
        _harness(AppState.initial().copyWith(isBootstrapped: true)),
      );
      await tester.pumpAndSettle();

      // Question option renders (regression: cards were hidden behind a
      // full-screen disabled button).
      expect(find.text('跑步'), findsWidgets);

      // The "Answer all blanks" bottom button must stay a normal-sized button,
      // not expand to fill the screen (which covered all the question cards).
      final button = find.byType(AppPrimaryButton);
      expect(button, findsOneWidget);
      expect(tester.getSize(button).height, lessThan(120));
    },
  );
}
