import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/features/training/training_session_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:linguaquest/l10n/generated/app_localizations_en.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

List<CustomWord> _threeWords() {
  final now = DateTime(2026, 1, 1);
  return [
    CustomWord.create(
      id: 'w1',
      uid: 'u1',
      word: '爱',
      meaning: '爱',
      exampleSentence: '',
      now: now,
      englishDefinitions: const ['to love'],
    ),
    CustomWord.create(
      id: 'w2',
      uid: 'u1',
      word: '你',
      meaning: '你',
      exampleSentence: '',
      now: now,
      englishDefinitions: const ['you'],
    ),
    CustomWord.create(
      id: 'w3',
      uid: 'u1',
      word: '好',
      meaning: '好',
      exampleSentence: '',
      now: now,
      englishDefinitions: const ['good'],
    ),
  ];
}

Future<void> _pumpTraining(
  WidgetTester tester, {
  required String gameId,
}) async {
  final state = AppState.initial().copyWith(
    isBootstrapped: true,
    customWords: _threeWords(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appControllerProvider.overrideWith(() => _FakeAppController(state)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: TrainingSessionScreen(gameId: gameId),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('D-03 spelling prompt/label do not name the wrong language (English)', () {
    final en = AppLocalizationsEn();
    // The answer is the learned target word (e.g. Chinese 爱), while the shown
    // cue is its meaning. The prompt must not claim the user should spell the
    // English word.
    expect(
      en.trainingPromptChineseSpelling('to love').toLowerCase(),
      isNot(contains('english')),
    );
    expect(
      en.trainingPromptAudioSpelling('ài').toLowerCase(),
      isNot(contains('english')),
    );
    expect(
      en.trainingSpellingInputLabel.toLowerCase(),
      isNot(contains('english')),
    );
  });

  testWidgets(
    'D-02 survival resource pill labels revives and nodes correctly',
    (tester) async {
      await _pumpTraining(tester, gameId: 'survival');
      // Initial state: revives = 1, nodeRewards = 0.
      expect(find.textContaining('Revives 1'), findsOneWidget);
      expect(find.textContaining('Nodes 0'), findsOneWidget);
    },
  );

  testWidgets(
    'D-04 listening options stay hidden until the audio is played',
    (tester) async {
      await _pumpTraining(tester, gameId: 'listening-sprint');
      // Before playing the audio, the candidate word options (which include the
      // answer text) must not be exposed.
      expect(find.byType(WordChoiceButton), findsNothing);

      // Playing the audio reveals the options so the user can still answer.
      await tester.tap(find.text('Audio'));
      await tester.pump();
      expect(find.byType(WordChoiceButton), findsWidgets);
    },
  );
}
