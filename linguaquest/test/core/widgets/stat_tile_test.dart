import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/stat_tile.dart';

void main() {
  testWidgets('StatTile renders value and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatTile(value: '42', label: 'streak days', icon: Icons.bolt),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('streak days'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('StatTile constrains value and label text', (tester) async {
    const value = '1234567890';
    const label = 'Very Long Combo Target Label';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: StatTile(value: value, label: label, icon: Icons.bolt),
          ),
        ),
      ),
    );

    final valueText = tester.widget<Text>(find.text(value));
    final labelText = tester.widget<Text>(find.text(label));
    expect(valueText.maxLines, 1);
    expect(valueText.overflow, TextOverflow.ellipsis);
    expect(labelText.maxLines, 1);
    expect(labelText.overflow, TextOverflow.ellipsis);
  });
}
