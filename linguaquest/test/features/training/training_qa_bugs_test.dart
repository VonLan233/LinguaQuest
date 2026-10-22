import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/learning_badges.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
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

Word _word({
  required String id,
  required String word,
  required String meaning,
  required String definition,
  String exampleSentence = '',
}) {
  return Word(
    id: id,
    word: word,
    phonetic: '',
    meaning: meaning,
    definition: definition,
    partOfSpeech: 'word',
    exampleSentence: exampleSentence,
    exampleTranslation: '',
    imageCue: word,
    difficulty: 'Easy',
    tags: const [],
    definitions: [meaning],
    englishDefinitions: [definition],
  );
}

List<Word> _lessonWords() {
  return [
    _word(id: 'w1', word: '爱', meaning: '爱', definition: 'to love'),
    _word(id: 'w2', word: '八', meaning: '八', definition: 'eight'),
    _word(id: 'w3', word: '爸', meaning: '爸', definition: 'father'),
    _word(id: 'w4', word: '好', meaning: '好', definition: 'good'),
  ];
}

Lesson _trainingLesson({required String id, required String title}) {
  final words = _lessonWords();
  final questionWord = words.first;
  return Lesson(
    id: id,
    title: title,
    section: '训练场',
    description: 'Training pack',
    status: 'current',
    xpReward: 20,
    estimatedMinutes: 5,
    words: words,
    questions: [
      QuizQuestion(
        id: '$id-q0',
        type: QuizQuestionType.meaningChoice,
        prompt: 'Select the English meaning of "${questionWord.word}".',
        answer: questionWord.definition,
        options: const ['to love', 'eight', 'father', 'good'],
        explanation: '"爱" means to love.',
        word: questionWord,
      ),
    ],
  );
}

Lesson _formalLesson() {
  final words = _lessonWords();
  return Lesson(
    id: 'formal-lesson-1',
    title: 'Starter Lesson',
    section: 'HSK 1',
    description: 'Formal lesson',
    status: 'current',
    xpReward: 20,
    estimatedMinutes: 5,
    words: words,
    questions: const [],
  );
}

Future<void> _pumpTraining(
  WidgetTester tester, {
  required String gameId,
  AppState? state,
}) async {
  final effectiveState =
      state ??
      AppState.initial().copyWith(
        isBootstrapped: true,
        customWords: _threeWords(),
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appControllerProvider.overrideWith(
          () => _FakeAppController(effectiveState),
        ),
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

Future<void> _pumpTimedQuiz(WidgetTester tester) async {
  final lesson = _trainingLesson(
    id: 'hsk1-training-speed',
    title: 'Campus Sprint',
  );
  final state = AppState.initial().copyWith(
    isBootstrapped: true,
    lessons: [lesson],
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
        home: QuizSessionScreen(
          lessonId: lesson.id,
          mode: QuizSessionMode.timed,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test(
    'D-03 spelling prompt/label do not name the wrong language (English)',
    () {
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
    },
  );

  testWidgets(
    'D-02 survival resource pill labels revives and nodes correctly',
    (tester) async {
      await _pumpTraining(tester, gameId: 'survival');
      // Initial state: revives = 1, nodeRewards = 0.
      expect(find.textContaining('Revives 1'), findsOneWidget);
      expect(find.textContaining('Nodes 0'), findsOneWidget);
    },
  );

  testWidgets('D-04 listening options stay hidden until the audio is played', (
    tester,
  ) async {
    await _pumpTraining(tester, gameId: 'listening-sprint');
    // Before playing the audio, the candidate word options (which include the
    // answer text) must not be exposed.
    expect(find.byType(WordChoiceButton), findsNothing);

    // The top cue badge must also hide the target word's character (it would
    // leak the answer); it renders a neutral icon instead until answered.
    final badge = tester.widget<ImageCueBadge>(find.byType(ImageCueBadge));
    expect(badge.icon, isNotNull);

    // Playing the audio reveals the options so the user can still answer.
    await tester.tap(find.text('Audio'));
    await tester.pump();
    expect(find.byType(WordChoiceButton), findsWidgets);
  });

  testWidgets(
    'timed training quiz title uses the mode name instead of Timed Test',
    (tester) async {
      await _pumpTimedQuiz(tester);

      expect(find.text('Campus Sprint'), findsWidgets);
      expect(find.text('Timed Test'), findsNothing);
    },
  );

  testWidgets('survival Chinese-choice prompt does not reveal the answer cue', (
    tester,
  ) async {
    await _pumpTraining(
      tester,
      gameId: 'survival',
      state: AppState.initial().copyWith(
        isBootstrapped: true,
        lessons: [_formalLesson()],
      ),
    );

    await tester.tap(find.text('to love'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Choose the word for: eight'), findsOneWidget);
    final badge = tester.widget<ImageCueBadge>(find.byType(ImageCueBadge));
    expect(badge.icon, isNotNull);
  });

  testWidgets(
    'spelling feedback keeps the correct word inside quotes when example is empty',
    (tester) async {
      await _pumpTraining(tester, gameId: 'spelling');

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      await tester.tap(find.text('Submit spelling'));
      await tester.pump();

      expect(find.text('The correct spelling is "爱".'), findsOneWidget);
      expect(
        find.textContaining('The correct spelling is "". 爱'),
        findsNothing,
      );
    },
  );
}
