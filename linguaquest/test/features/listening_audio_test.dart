import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/pronunciation_controls.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/quiz/quiz_session_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

Word _makeWord({String audioUKUrl = '', String audioUSUrl = ''}) => Word(
      id: 'w1',
      word: '苹果',
      phonetic: 'píng guǒ',
      meaning: 'apple',
      definition: 'apple',
      partOfSpeech: 'n',
      exampleSentence: '',
      exampleTranslation: '',
      imageCue: '',
      difficulty: 'Easy',
      tags: const [],
      audioUKUrl: audioUKUrl,
      audioUSUrl: audioUSUrl,
    );

QuizQuestion _makeQuestion(QuizQuestionType type, Word word) => QuizQuestion(
      id: 'q1',
      type: type,
      prompt: 'What is this?',
      answer: 'apple',
      options: const ['apple', 'banana', 'cherry', 'date'],
      explanation: 'It is an apple.',
      word: word,
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  final listeningWord = _makeWord(
    audioUKUrl: 'https://example.com/uk.mp3',
    audioUSUrl: 'https://example.com/us.mp3',
  );

  group('QuizPromptPanel audio control', () {
    testWidgets(
      'PronunciationControls present for listeningWordChoice',
      (tester) async {
        final question = _makeQuestion(
          QuizQuestionType.listeningWordChoice,
          listeningWord,
        );
        await tester.pumpWidget(_wrap(QuizPromptPanel(question: question)));
        expect(find.byType(PronunciationControls), findsOneWidget);
      },
    );

    testWidgets(
      'PronunciationControls present for listeningMeaningChoice',
      (tester) async {
        final question = _makeQuestion(
          QuizQuestionType.listeningMeaningChoice,
          listeningWord,
        );
        await tester.pumpWidget(_wrap(QuizPromptPanel(question: question)));
        expect(find.byType(PronunciationControls), findsOneWidget);
      },
    );

    testWidgets(
      'PronunciationControls absent for non-listening question (meaningChoice)',
      (tester) async {
        final question = _makeQuestion(
          QuizQuestionType.meaningChoice,
          listeningWord,
        );
        await tester.pumpWidget(_wrap(QuizPromptPanel(question: question)));
        expect(find.byType(PronunciationControls), findsNothing);
      },
    );
  });
}
