import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/recall_buttons.dart';

void main() {
  testWidgets('RecallButtons renders all three labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecallButtons(
            unknownLabel: 'Again',
            fuzzyLabel: 'Hard',
            knownLabel: 'Good',
            onUnknown: () {},
            onFuzzy: () {},
            onKnown: () {},
          ),
        ),
      ),
    );

    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
  });

  testWidgets('RecallButtons fires each callback', (tester) async {
    var unknown = false;
    var fuzzy = false;
    var known = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecallButtons(
            unknownLabel: 'Again',
            fuzzyLabel: 'Hard',
            knownLabel: 'Good',
            onUnknown: () => unknown = true,
            onFuzzy: () => fuzzy = true,
            onKnown: () => known = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Again'));
    await tester.tap(find.text('Hard'));
    await tester.tap(find.text('Good'));
    await tester.pump();

    expect(unknown, isTrue);
    expect(fuzzy, isTrue);
    expect(known, isTrue);
  });
}
