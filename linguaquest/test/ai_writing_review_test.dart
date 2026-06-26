import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/models/ai_feature.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/ai_learning/ai_writing_review_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps the screen in a two-route navigator so that context.pop() from the
/// AppBar back button does not throw a "no routes to pop" error in tests.
Widget _buildScreen() {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProviderScope(
                  child: AiWritingReviewScreen(),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

/// Opens the screen by tapping the launcher button and settling.
Future<void> _openScreen(WidgetTester tester) async {
  await tester.pumpWidget(_buildScreen());
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Unit tests: WritingReviewResult ──────────────────────────────────────

  group('WritingReviewResult', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'totalScore': 75,
        'rubricScores': {
          'content': 18,
          'language': 15,
          'structure': 14,
          'vocabulary': 15,
          'accuracy': 13,
        },
        'mainIssues': ['Limited vocabulary variety'],
        'paragraphSuggestions': [
          {'paragraph': '1', 'suggestion': 'Strengthen your opening argument'},
        ],
        'highScoreExpressions': ['Furthermore, it is worth noting that...'],
        'grammarIssues': [
          {
            'original': 'I am agree',
            'corrected': 'I agree',
            'rule': 'Stative verb',
          },
        ],
        'rewrittenSample': 'Mock rewritten essay paragraph...',
      };
      final result = WritingReviewResult.fromJson(json);

      expect(result.totalScore, equals(75));
      expect(result.rubricScores['content'], equals(18));
      expect(result.mainIssues, contains('Limited vocabulary variety'));
      expect(result.highScoreExpressions, isNotEmpty);
      expect(result.grammarIssues.first['original'], equals('I am agree'));
      expect(result.rewrittenSample, equals('Mock rewritten essay paragraph...'));
    });

    test('toJson / fromJson round-trip preserves all values', () {
      const original = WritingReviewResult(
        totalScore: 80,
        rubricScores: {'content': 20, 'language': 16},
        mainIssues: ['Issue 1'],
        paragraphSuggestions: [],
        highScoreExpressions: ['Great phrase'],
        grammarIssues: [],
        rewrittenSample: 'Sample text',
      );
      final json = original.toJson();
      final restored = WritingReviewResult.fromJson(json);

      expect(restored.totalScore, equals(80));
      expect(restored.rubricScores['content'], equals(20));
      expect(restored.rubricScores['language'], equals(16));
      expect(restored.mainIssues, equals(['Issue 1']));
      expect(restored.highScoreExpressions, equals(['Great phrase']));
      expect(restored.rewrittenSample, equals('Sample text'));
    });

    test('empty() returns zero values without throwing', () {
      final empty = WritingReviewResult.empty();

      expect(empty.totalScore, equals(0));
      expect(empty.rubricScores, isEmpty);
      expect(empty.mainIssues, isEmpty);
      expect(empty.paragraphSuggestions, isEmpty);
      expect(empty.highScoreExpressions, isEmpty);
      expect(empty.grammarIssues, isEmpty);
      expect(empty.rewrittenSample, equals(''));
    });

    test('fromJson handles missing fields gracefully', () {
      final result = WritingReviewResult.fromJson({});

      expect(result.totalScore, equals(0));
      expect(result.rubricScores, isEmpty);
      expect(result.mainIssues, isEmpty);
      expect(result.rewrittenSample, equals(''));
    });

    test('fromJson handles non-numeric rubric values gracefully', () {
      final result = WritingReviewResult.fromJson({
        'totalScore': 60,
        'rubricScores': {'content': 15, 'language': 12},
      });

      expect(result.totalScore, equals(60));
      expect(result.rubricScores['content'], equals(15));
      expect(result.rubricScores['language'], equals(12));
    });
  });

  // ── Unit tests: MockAiRepository.reviewWriting ────────────────────────────

  group('MockAiRepository writing review', () {
    test('reviewWriting returns structured result with totalScore', () async {
      final repo = MockAiRepository();
      final result = await repo.reviewWriting(
        essay: 'My test essay content here.',
        targetLanguage: 'zh',
      );

      expect(result['totalScore'], equals(75));
      expect(result['rubricScores'], isA<Map>());
      expect(result['mainIssues'], isA<List>());
      expect(result['highScoreExpressions'], isA<List>());
      expect(result['grammarIssues'], isA<List>());
      expect(result['rewrittenSample'], isA<String>());
    });

    test('reviewWriting result can be parsed into WritingReviewResult', () async {
      final repo = MockAiRepository();
      final raw = await repo.reviewWriting(
        essay: 'Some essay content.',
        targetLanguage: 'zh',
      );
      final result = WritingReviewResult.fromJson(raw);

      expect(result.totalScore, greaterThan(0));
      expect(result.highScoreExpressions, isNotEmpty);
    });

    test('reviewWriting adds entry to history', () async {
      final repo = MockAiRepository();

      expect((await repo.listHistory()).length, equals(0));
      await repo.reviewWriting(
        essay: 'My test essay content here.',
        targetLanguage: 'zh',
      );
      final history = await repo.listHistory();

      expect(history.length, equals(1));
      expect(history.first.featureType, equals('writing_review'));
    });

    test('reviewWriting stores essay as prompt in history entry', () async {
      final repo = MockAiRepository();
      const essay = 'Test essay for prompt storage.';
      await repo.reviewWriting(essay: essay, targetLanguage: 'zh');
      final history = await repo.listHistory();

      expect(history.first.prompt, equals(essay));
    });

    test('reviewWriting with examType still stores essay as prompt', () async {
      final repo = MockAiRepository();
      await repo.reviewWriting(
        essay: 'Test essay',
        examType: 'IELTS',
        targetLanguage: 'zh',
      );
      final history = await repo.listHistory();

      expect(history.first.prompt, equals('Test essay'));
      expect(history.first.featureType, equals('writing_review'));
    });

    test('multiple reviewWriting calls accumulate in history', () async {
      final repo = MockAiRepository();
      await repo.reviewWriting(essay: 'First essay.', targetLanguage: 'zh');
      await repo.reviewWriting(essay: 'Second essay.', targetLanguage: 'zh');
      final history = await repo.listHistory();

      expect(history.length, equals(2));
      // Most recent first.
      expect(history.first.prompt, equals('Second essay.'));
    });

    test('reviewWriting history entry has valid id', () async {
      final repo = MockAiRepository();
      await repo.reviewWriting(essay: 'Essay with id check.', targetLanguage: 'zh');
      final history = await repo.listHistory();

      expect(history.first.id, isNotEmpty);
      expect(history.first.id, startsWith('mock-wr-'));
    });
  });

  // ── Widget tests: AiWritingReviewScreen ───────────────────────────────────

  group('AiWritingReviewScreen', () {
    testWidgets('renders input form without crash', (tester) async {
      await _openScreen(tester);

      expect(find.text('AI Writing Review'), findsOneWidget);
      expect(find.text('Exam Type'), findsOneWidget);
      expect(find.text('Your Essay'), findsOneWidget);
      expect(find.text('Submit for Review'), findsOneWidget);
    });

    testWidgets('renders all default exam type chips', (tester) async {
      await _openScreen(tester);

      expect(find.text('General'), findsOneWidget);
      expect(find.text('IELTS'), findsOneWidget);
      expect(find.text('CET-4'), findsOneWidget);
      expect(find.text('CET-6'), findsOneWidget);
      expect(find.text('TOEFL'), findsOneWidget);
    });

    testWidgets('shows character count hint for essay field', (tester) async {
      await _openScreen(tester);

      expect(find.textContaining('/ 3000 characters'), findsOneWidget);
    });

    testWidgets('shows validation error when essay is too short', (tester) async {
      await _openScreen(tester);

      await tester.tap(find.text('Submit for Review'));
      await tester.pump();

      expect(
        find.text('Essay must be at least 50 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error when essay field is empty', (tester) async {
      await _openScreen(tester);

      await tester.tap(find.text('Submit for Review'));
      await tester.pump();

      // Empty string has length 0, which is less than 50.
      expect(
        find.text('Essay must be at least 50 characters'),
        findsOneWidget,
      );
    });

    testWidgets('updates character count as user types', (tester) async {
      await _openScreen(tester);

      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();

      expect(find.text('5 / 3000 characters'), findsOneWidget);
    });

    testWidgets('can select a different exam type chip', (tester) async {
      await _openScreen(tester);

      await tester.tap(find.text('IELTS'));
      await tester.pump();

      // After tapping IELTS, it should be selected (ChoiceChip is selected).
      final ieltsChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('IELTS'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(ieltsChip.selected, isTrue);
    });

    testWidgets('does not show result view initially', (tester) async {
      await _openScreen(tester);

      // Result-specific widgets should not be visible in the input phase.
      expect(find.text('Overall Score'), findsNothing);
      expect(find.text('Score Breakdown'), findsNothing);
      expect(find.text('New Essay'), findsNothing);
    });
  });
}
