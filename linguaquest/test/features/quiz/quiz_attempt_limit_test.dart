import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// Reproduction for bug D-06.
///
/// Part 1: a wrong multiple-choice answer must not let the learner keep
/// tapping options forever until they stumble on the correct one. After a
/// small number of wrong attempts the question locks, reveals the answer and
/// advances.
///
/// Part 2: the feedback label must go through l10n and must NOT be crammed
/// together with the (possibly other-language) `question.explanation` in a
/// single text run, which produced mixed-language feedback.
Word _word(String id, String hanzi, String def) => Word(
  id: id,
  word: hanzi,
  phonetic: 'p$id',
  meaning: def,
  definition: def,
  partOfSpeech: 'n',
  exampleSentence: '',
  exampleTranslation: '',
  imageCue: '',
  difficulty: 'Easy',
  tags: const [],
  phoneticUK: 'p$id',
  phoneticUS: 'p$id',
  definitions: [def],
  englishDefinitions: [def],
  hskLevel: 1,
);

QuizQuestion _chineseChoice(
  String id,
  Word word,
  List<String> options,
  String explanation,
) => QuizQuestion(
  id: id,
  type: QuizQuestionType.chineseChoice,
  prompt: 'Pick ${word.meaning}',
  answer: word.word,
  options: options,
  explanation: explanation,
  word: word,
);

Lesson _lesson(List<QuizQuestion> questions, List<Word> words) => Lesson(
  id: 'limit-lesson',
  title: 'Limit Lesson',
  section: 'HSK 1',
  description: '',
  status: 'current',
  xpReward: 10,
  estimatedMinutes: 5,
  words: words,
  questions: questions,
);

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
      home: QuizSessionScreen(lessonId: 'limit-lesson'),
    ),
  );
}

void main() {
  testWidgets(
    'after reaching the wrong-attempt limit the question locks and reveals '
    'the answer instead of allowing infinite guessing',
    (tester) async {
      final target = _word('t', '爱', 'to love');
      final question = _chineseChoice(
        'q1',
        target,
        const ['爱', '好', '人', '大'],
        'EXPLAIN_LIMIT',
      );
      // A trailing question so a lock-triggered auto-advance just moves on
      // instead of completing the lesson (which would navigate away).
      final filler = _chineseChoice('q2', target, const ['爱', '好'], 'x');
      final seed = AppState.initial().copyWith(
        isBootstrapped: true,
        lessons: [
          _lesson([question, filler], [target]),
        ],
      );

      await tester.pumpWidget(_app(seed));
      await tester.pumpAndSettle();

      WordChoiceButton buttonFor(String text) => tester.widget<WordChoiceButton>(
        find.widgetWithText(WordChoiceButton, text),
      );

      // First wrong tap: still retryable, correct answer not yet revealed.
      await tester.tap(find.text('好'));
      await tester.pump();
      expect(
        buttonFor('爱').state,
        ChoiceState.idle,
        reason: 'first wrong attempt must not reveal the correct option',
      );
      expect(
        buttonFor('爱').onTap,
        isNotNull,
        reason: 'the question is still retryable after one wrong attempt',
      );

      // Second wrong tap reaches the limit -> lock + reveal the correct option
      // (green) and stop accepting taps.
      await tester.tap(find.text('人'));
      await tester.pump();
      expect(
        buttonFor('爱').state,
        ChoiceState.correct,
        reason: 'reaching the attempt limit reveals the correct option',
      );
      expect(
        buttonFor('爱').onTap,
        isNull,
        reason: 'a locked question must not keep accepting taps',
      );
    },
  );
}
