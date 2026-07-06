import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// Reproduction for test task 6.2: "answered every question correctly but every
/// word still lands in the mistake book".
///
/// The formal-course quiz judges a tapped choice with
/// `option.toLowerCase() == question.answer.toLowerCase()` (no trim). Options
/// are trimmed at generation (`_choiceOptions`), but `QuizQuestion.answer` for
/// word-answer types is the raw `word.word`, which `_string` does NOT trim.
/// So a wordbook entry whose `word` carries stray whitespace (a realistic
/// remote/custom-word trust-boundary input) makes the correct pick judge WRONG,
/// which then records it as a mistake even though the learner chose correctly.
Word _word(String id, String hanzi, String pinyin, String meaning) => Word(
  id: id,
  word: hanzi,
  phonetic: pinyin,
  meaning: meaning,
  definition: meaning,
  partOfSpeech: 'n',
  exampleSentence: '',
  exampleTranslation: '',
  imageCue: '',
  difficulty: 'Easy',
  tags: const [],
  phoneticUK: pinyin,
  phoneticUS: pinyin,
  definitions: [meaning],
  englishDefinitions: [meaning],
  hskLevel: 1,
);

/// A formal (non-training) lesson with a chineseChoice question whose answer
/// word has a trailing space, mirroring dirty wordbook data.
Lesson _lessonWithWhitespaceAnswer() {
  // Trailing space on the answer word; distractor is clean.
  final answerWord = _word('a', '爱 ', 'ai', 'to love');
  final distractor = _word('b', '好', 'hao', 'good');
  return Lesson(
    id: 'ws-lesson',
    title: 'Whitespace Lesson',
    section: 'HSK 1',
    description: '',
    status: 'current',
    xpReward: 10,
    estimatedMinutes: 5,
    words: [answerWord, distractor],
    questions: buildQuestionsForWords(
      lessonId: 'ws-lesson',
      words: [answerWord, distractor],
      distractorWords: [answerWord, distractor],
      forceType: QuizQuestionType.chineseChoice,
    ),
  );
}

class _SeedController extends AppController {
  _SeedController(this._seed);

  final AppState _seed;

  @override
  AppState build() => _seed;
}

Widget _app(AppState seed) {
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(() => _SeedController(seed)),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: QuizSessionScreen(lessonId: 'ws-lesson'),
    ),
  );
}

void main() {
  testWidgets(
    'tapping the correct option is judged CORRECT even when the answer '
    'word carries stray whitespace',
    (tester) async {
      final seed = AppState.initial().copyWith(
        isBootstrapped: true,
        lessons: [_lessonWithWhitespaceAnswer()],
      );

      await tester.pumpWidget(_app(seed));
      await tester.pumpAndSettle();

      // The rendered option button shows the trimmed word.
      expect(find.text('爱'), findsOneWidget);
      await tester.tap(find.text('爱'));
      await tester.pump(); // settle the setState from _judge, before auto-advance

      // A correct pick locks the question and marks that option green
      // (ChoiceState.correct); if the judge mis-scored it, the option would be
      // flagged wrong instead.
      final button = tester.widget<WordChoiceButton>(
        find.widgetWithText(WordChoiceButton, '爱'),
      );
      expect(
        button.state,
        ChoiceState.correct,
        reason: 'correct pick must be judged correct, not wrong',
      );
    },
  );
}
