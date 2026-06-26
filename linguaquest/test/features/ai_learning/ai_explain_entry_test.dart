import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/lesson_result.dart';
import 'package:linguaquest/features/quiz/lesson_result_screen.dart';
import 'package:linguaquest/features/review/mistake_book_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal [Word] used as a mistake in tests.
Word _makeWord(String wordText) => Word(
      id: 'test-word-id',
      word: wordText,
      phonetic: '',
      meaning: 'test meaning',
      definition: 'test definition',
      partOfSpeech: 'noun',
      exampleSentence: 'example',
      exampleTranslation: 'translation',
      imageCue: '📖',
      difficulty: 'easy',
      tags: const [],
    );

/// A minimal [QuizQuestion] containing [word].
QuizQuestion _makeQuestion(Word word) => QuizQuestion(
      id: 'q1',
      type: QuizQuestionType.meaningChoice,
      prompt: 'What is ${word.word}?',
      answer: word.word,
      options: const [],
      explanation: 'test explanation',
      word: word,
    );

/// A [LessonResult] with one mistake for [wordText].
LessonResult _makeResult(String wordText) {
  final word = _makeWord(wordText);
  final question = _makeQuestion(word);
  return LessonResult(
    lessonId: 'lesson-1',
    lessonTitle: 'Test Lesson',
    totalQuestions: 2,
    correctAnswers: 1,
    xpEarned: 10,
    mistakes: [question],
    completedAt: DateTime(2026, 6, 26),
  );
}

// ---------------------------------------------------------------------------
// Fake AppController for MistakeBookScreen
// ---------------------------------------------------------------------------

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;

  @override
  AppState build() => _state;
}

// ---------------------------------------------------------------------------
// Router helpers
// ---------------------------------------------------------------------------

/// Captures the word query-param received by the /ai-chat stub route.
String? _capturedAiChatWord;

GoRoute _aiChatStubRoute() => GoRoute(
      path: '/ai-chat',
      builder: (context, state) {
        _capturedAiChatWord = state.uri.queryParameters['word'];
        return const Scaffold(body: Text('ai-chat'));
      },
    );

Widget _buildLessonResultApp({required LessonResult result}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LessonResultScreen(result: result),
      ),
      _aiChatStubRoute(),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
}

Widget _buildMistakeBookApp({required LessonResult result}) {
  final initialState = AppState.initial().copyWith(lastResult: result);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MistakeBookScreen(),
      ),
      _aiChatStubRoute(),
      GoRoute(
        path: '/review',
        builder: (context, state) => const Scaffold(body: Text('review')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appControllerProvider
          .overrideWith(() => _FakeAppController(initialState)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final result = _makeResult('试');

  setUp(() {
    _capturedAiChatWord = null;
  });

  testWidgets(
    'LessonResultScreen: explain button exists and navigates to /ai-chat?word=',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_buildLessonResultApp(result: result));
      await tester.pumpAndSettle();

      // Scroll until the mistake row with the explain button is visible.
      await tester.scrollUntilVisible(
        find.byTooltip(l10n.aiExplainWithAi),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // The explain button should be present.
      final explainBtn = find.byTooltip(l10n.aiExplainWithAi);
      expect(explainBtn, findsOneWidget);

      // Tapping should navigate to /ai-chat with the word as query param.
      await tester.tap(explainBtn);
      await tester.pumpAndSettle();

      // The /ai-chat stub captured the word query parameter.
      expect(_capturedAiChatWord, isNotEmpty);
      expect(find.text('ai-chat'), findsOneWidget);
    },
  );

  testWidgets(
    'MistakeBookScreen: explain button exists and navigates to /ai-chat?word=',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_buildMistakeBookApp(result: result));
      await tester.pumpAndSettle();

      // The explain button should be present in the mistake row.
      final explainBtn = find.byTooltip(l10n.aiExplainWithAi);
      expect(explainBtn, findsOneWidget);

      // Tapping should navigate to /ai-chat with the word as query param.
      await tester.tap(explainBtn);
      await tester.pumpAndSettle();

      // The /ai-chat stub captured the word query parameter.
      expect(_capturedAiChatWord, isNotEmpty);
      expect(find.text('ai-chat'), findsOneWidget);
    },
  );
}
