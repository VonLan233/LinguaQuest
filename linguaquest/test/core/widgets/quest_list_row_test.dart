import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/quest_list_row.dart';

void main() {
  testWidgets('QuestListRow renders title, subtitle and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestListRow(
            icon: Icons.book,
            title: 'Vocabulary',
            subtitle: '12 words',
            value: '80%',
          ),
        ),
      ),
    );

    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('12 words'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('QuestListRow fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestListRow(
            icon: Icons.book,
            title: 'Tap row',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap row'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
