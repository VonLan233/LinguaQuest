import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/word_choice_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WordChoiceButton renders letter and text', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WordChoiceButton(letter: 'A', text: 'apple'),
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
  });

  testWidgets('WordChoiceButton fires onTap when idle', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WordChoiceButton(
              letter: 'B',
              text: 'banana',
              onTap: () => tapped = true,
            ),
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
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WordChoiceButton(
              letter: 'C',
              text: 'cherry',
              state: ChoiceState.correct,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('cherry'));
    await tester.pump();
    expect(tapped, isFalse);
  });
}
