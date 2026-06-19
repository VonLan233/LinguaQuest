import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/app_progress_bar.dart';

void main() {
  testWidgets('AppProgressBar clamps value into 0..1', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: AppProgressBar(value: 1.5)),
        ),
      ),
    );
    final bar = tester.widget<AppProgressBar>(find.byType(AppProgressBar));
    expect(bar.value, 1.5); // raw value preserved
    expect(find.byType(FractionallySizedBox), findsOneWidget);
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 1.0); // clamped for layout
  });

  testWidgets('AppProgressBar renders zero progress without overflow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: AppProgressBar(value: 0)),
        ),
      ),
    );
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.0);
  });

  testWidgets('AppProgressBar clamps negative value up to 0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: AppProgressBar(value: -0.5)),
        ),
      ),
    );
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.0);
  });
}
