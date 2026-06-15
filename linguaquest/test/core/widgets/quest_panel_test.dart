import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/quest_panel.dart';

void main() {
  testWidgets('QuestPanel renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestPanel(child: Text('panel content')),
        ),
      ),
    );

    expect(find.text('panel content'), findsOneWidget);
  });

  testWidgets('QuestPanel fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestPanel(
            onTap: () => tapped = true,
            child: const Text('tap me'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
