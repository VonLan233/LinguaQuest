import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/wordbook_cover_card.dart';

void main() {
  testWidgets('WordbookCoverCard renders exam badge + title (no network)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WordbookCoverCard(
            examType: 'IELTS',
            bookId: 'ielts',
            title: '雅思核心词汇',
          ),
        ),
      ),
    );

    expect(find.text('IELTS'), findsOneWidget);
    expect(find.text('雅思核心词汇'), findsOneWidget);
    // Programmatic cover — must not pull a network image.
    expect(find.byType(Image), findsNothing);
  });

  test('paletteFor is deterministic and exam-keyed', () {
    final ielts = WordbookCoverCard.paletteFor('IELTS', 'ielts');
    final gre = WordbookCoverCard.paletteFor('GRE', 'gre');
    expect(ielts.top, isNot(equals(gre.top)));
    // Same key resolves identically regardless of casing.
    expect(
      WordbookCoverCard.paletteFor('ielts', 'ielts').top,
      equals(ielts.top),
    );
  });

  test('badge falls back to book id when examType is empty', () {
    const card = WordbookCoverCard(examType: '', bookId: 'beginner', title: 'x');
    expect(card.examType, isEmpty);
    // Palette still resolves via the bookId key.
    final palette = WordbookCoverCard.paletteFor('', 'beginner');
    expect(palette, isA<WordbookCoverPalette>());
  });
}
