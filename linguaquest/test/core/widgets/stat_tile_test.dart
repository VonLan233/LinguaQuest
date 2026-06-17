import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/stat_tile.dart';

void main() {
  testWidgets('StatTile renders value and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatTile(
            value: '42',
            label: 'streak days',
            icon: Icons.bolt,
          ),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('streak days'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });
}
