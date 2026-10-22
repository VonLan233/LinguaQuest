import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/ai_word_support_link.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/lesson_result.dart';
import 'package:linguaquest/features/ai_learning/ai_learning_screen.dart';
import 'package:linguaquest/features/quiz/lesson_result_screen.dart';
import 'package:linguaquest/features/review/mistake_book_screen.dart';
import 'package:linguaquest/features/shell/app_shell.dart';
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

/// Captures the word query-param received by the /ai-learning stub route.
String? _capturedAiLearningWord;

GoRoute _aiLearningStubRoute() => GoRoute(
  path: '/ai-learning',
  builder: (context, state) {
    _capturedAiLearningWord = state.uri.queryParameters['word'];
    return const Scaffold(body: Text('ai-learning'));
  },
);

Widget _buildLessonResultApp({required LessonResult result}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LessonResultScreen(result: result),
      ),
      _aiLearningStubRoute(),
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
      _aiLearningStubRoute(),
      GoRoute(
        path: '/review',
        builder: (context, state) => const Scaffold(body: Text('review')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(
        () => _FakeAppController(initialState),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
}

Widget _buildRealShellAiLinkApp() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: AiWordSupportLink(word: '爱')),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(selectedIndex: 2, child: child);
        },
        routes: [
          GoRoute(
            path: '/ai-learning',
            builder: (context, state) => const AiLearningScreen(),
          ),
        ],
      ),
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final result = _makeResult('试');

  setUp(() {
    _capturedAiLearningWord = null;
  });

  testWidgets(
    'LessonResultScreen: explain button exists and navigates to /ai-learning?word=',
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

      // Tapping should navigate to /ai-learning with the word as query param.
      await tester.tap(explainBtn);
      await tester.pumpAndSettle();

      // The /ai-learning stub captured the word query parameter.
      expect(_capturedAiLearningWord, isNotEmpty);
      expect(find.text('ai-learning'), findsOneWidget);
    },
  );

  testWidgets(
    'MistakeBookScreen: explain button exists and navigates to /ai-learning?word=',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_buildMistakeBookApp(result: result));
      await tester.pumpAndSettle();

      // The explain button should be present in the mistake row.
      final explainBtn = find.byTooltip(l10n.aiExplainWithAi);
      expect(explainBtn, findsOneWidget);

      // Tapping should navigate to /ai-learning with the word as query param.
      await tester.tap(explainBtn);
      await tester.pumpAndSettle();

      // The /ai-learning stub captured the word query parameter.
      expect(_capturedAiLearningWord, isNotEmpty);
      expect(find.text('ai-learning'), findsOneWidget);
    },
  );

  testWidgets(
    'MistakeBookScreen: explain button stays visible/tappable at narrow width '
    '(SVV D-09 regression)',
    (tester) async {
      // Narrow viewport forces the mistake-row children to compete for width.
      // Without the Flexible pill wrapper, the row overflows and pushes the
      // Explain-with-AI IconButton out of the visible/tappable area.
      tester.view.physicalSize = const Size(200, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_buildMistakeBookApp(result: result));
      await tester.pumpAndSettle();

      // No RenderFlex overflow should have been thrown during layout.
      expect(tester.takeException(), isNull);

      final explainBtn = find.byTooltip(l10n.aiExplainWithAi);
      expect(explainBtn, findsOneWidget);

      // The button must be actually tappable (hit-testable, on-screen).
      await tester.tap(explainBtn);
      await tester.pumpAndSettle();

      expect(_capturedAiLearningWord, isNotEmpty);
      expect(find.text('ai-learning'), findsOneWidget);
    },
  );

  testWidgets(
    'AiWordSupportLink navigates from a non-shell page into the real AI shell',
    (tester) async {
      await tester.pumpWidget(_buildRealShellAiLinkApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI Learning'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AI Learning'), findsWidgets);
      expect(find.text('爱'), findsOneWidget);
    },
  );
}
