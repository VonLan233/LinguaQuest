import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/top_notice.dart';

void main() {
  testWidgets('showTopNotice shows a top-anchored notice and auto-dismisses',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showTopNotice(ctx, 'done'),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    // Advance the entrance animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('done'), findsOneWidget);

    // Top-anchored: above the vertical midpoint of the Scaffold.
    final c = tester.getCenter(find.text('done'));
    expect(c.dy, lessThan(tester.getSize(find.byType(Scaffold)).height / 2));

    // Auto-dismiss after the default duration.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('done'), findsNothing);

    await tester.pumpAndSettle();
  });
}
