import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/progress_ring.dart';

void main() {
  testWidgets('ProgressRing renders center labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressRing(
            progress: 0.65,
            centerLabel: '65%',
            centerSubLabel: 'done',
          ),
        ),
      ),
    );

    expect(find.text('65%'), findsOneWidget);
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('ProgressRing does not throw for boundary values', (
    tester,
  ) async {
    for (final value in [0.0, 0.65, 1.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProgressRing(progress: value)),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
