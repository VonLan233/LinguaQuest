// test/features/ai_learning/ai_error_retry_test.dart
//
// Spec §9(c): widget tests for EMPTY / ERROR / RETRY states on AiChatScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/widgets/ai_error_card.dart';
import 'package:linguaquest/data/models/ai_feature.dart';
import 'package:linguaquest/data/repositories/ai_repository.dart';
import 'package:linguaquest/features/ai_learning/ai_chat_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake AiRepository: throws on first chat(), succeeds on second
// ---------------------------------------------------------------------------

class _ThrowThenSucceedAiRepository implements AiRepository {
  int _chatCallCount = 0;

  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    _chatCallCount++;
    if (_chatCallCount == 1) {
      throw Exception('Simulated network failure');
    }
    return {
      'answer': 'Hello means a common greeting in English.',
      'cautions': <String>[],
      'relatedWords': <String>['hi', 'hey'],
    };
  }

  @override
  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> generateConfusion({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> generateSentences({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> explainParagraph({
    required String paragraph,
    required String language,
    String? level,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<AiHistoryEntry>> listHistory() async => [];

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  }) async =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _buildApp(_ThrowThenSucceedAiRepository fakeRepo) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AiChatScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      aiRepositoryProvider.overrideWithValue(fakeRepo),
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
  late _ThrowThenSucceedAiRepository fakeRepo;

  setUp(() {
    fakeRepo = _ThrowThenSucceedAiRepository();
  });

  testWidgets(
    '(a) empty guidance aiEmptyChat is shown before any submit',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Default scope is Chinese; helper text is parameterized by language.
      expect(find.text(l10n.aiEmptyChat(l10n.pickerLanguageChinese)), findsOneWidget);
      expect(find.byType(AiErrorCard), findsNothing);
    },
  );

  testWidgets(
    '(b) first submit → error → AiErrorCard with Retry shown, no result card',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Enter a prompt
      await tester.enterText(find.byType(TextFormField), 'What does hello mean?');

      // Tap Ask
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      // AiErrorCard should be visible
      expect(find.byType(AiErrorCard), findsOneWidget);

      // Retry button inside the card
      expect(find.text(l10n.commonRetry), findsOneWidget);

      // No answer text (result card not rendered)
      expect(
        find.text('Hello means a common greeting in English.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    '(c) tap Retry → error card gone, answer text renders',
    (tester) async {
      await tester.pumpWidget(_buildApp(fakeRepo));
      await tester.pumpAndSettle();

      // Enter prompt and submit (first call — throws → error card shown)
      await tester.enterText(find.byType(TextFormField), 'What does hello mean?');
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      expect(find.byType(AiErrorCard), findsOneWidget);

      // Tap Retry (second call — succeeds)
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      // Error card gone
      expect(find.byType(AiErrorCard), findsNothing);

      // Answer text rendered somewhere on screen
      expect(
        find.textContaining('Hello means a common greeting in English.'),
        findsOneWidget,
      );
    },
  );
}
