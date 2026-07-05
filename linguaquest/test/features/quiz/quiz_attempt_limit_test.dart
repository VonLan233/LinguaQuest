import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
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

      // First wrong tap: still retryable, answer not revealed.
      await tester.tap(find.text('好'));
      await tester.pump();
      expect(
        find.textContaining('Reinforce'),
        findsNothing,
        reason: 'first wrong attempt must not reveal the answer',
      );
      expect(find.textContaining('Retry'), findsOneWidget);

      // Second wrong tap reaches the limit -> lock + reveal, no more retries.
      await tester.tap(find.text('人'));
      await tester.pump();
      expect(
        find.textContaining('Reinforce'),
        findsOneWidget,
        reason: 'reaching the attempt limit must reveal the answer',
      );
      expect(
        find.textContaining('Retry'),
        findsNothing,
        reason: 'a locked question must not keep inviting retries',
      );
    },
  );

  testWidgets(
    'correct feedback keeps the l10n label and the explanation as separate '
    'text runs (no mixed-language concatenation)',
    (tester) async {
      final target = _word('t', '爱', 'to love');
      final question = _chineseChoice(
        'q1',
        target,
        const ['爱', '好'],
        'EXPLAIN_CONTENT',
      );
      final filler = _chineseChoice('q2', target, const ['爱', '好'], 'x');
      final seed = AppState.initial().copyWith(
        isBootstrapped: true,
        lessons: [
          _lesson([question, filler], [target]),
        ],
      );

      await tester.pumpWidget(_app(seed));
      await tester.pumpAndSettle();

      await tester.tap(find.text('爱')); // correct
      await tester.pump();

      // The explanation must render as its own Text, not concatenated into the
      // localized label run. If it were crammed into 'Correct. EXPLAIN_CONTENT'
      // the exact-text finder would fail.
      expect(
        find.text('EXPLAIN_CONTENT'),
        findsOneWidget,
        reason: 'explanation must not be crammed into the l10n label run',
      );
    },
  );
}
