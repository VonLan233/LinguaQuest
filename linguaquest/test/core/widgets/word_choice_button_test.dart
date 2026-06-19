import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';

void main() {
  testWidgets('WordChoiceButton renders letter and text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WordChoiceButton(letter: 'A', text: 'apple'),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('WordChoiceButton fires onTap when idle', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordChoiceButton(
            letter: 'B',
            text: 'banana',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('banana'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('WordChoiceButton ignores taps in terminal states', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordChoiceButton(
            letter: 'C',
            text: 'cherry',
            state: ChoiceState.correct,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('cherry'));
    await tester.pump();
    expect(tapped, isFalse);
  });
}
