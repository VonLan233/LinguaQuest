import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge renders label and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            label: 'Due now',
            tone: StatusTone.warning,
            icon: Icons.schedule,
          ),
        ),
      ),
    );

    expect(find.text('Due now'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('StatusBadge renders for every tone', (tester) async {
    for (final tone in StatusTone.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusBadge(label: tone.name, tone: tone)),
        ),
      );
      expect(find.text(tone.name), findsOneWidget);
    }
  });
}
