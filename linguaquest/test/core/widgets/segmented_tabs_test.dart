import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/segmented_tabs.dart';

void main() {
  testWidgets('SegmentedTabs renders labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedTabs(
            labels: const ['All', 'New', 'Review'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('SegmentedTabs fires onChanged with tapped index', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedTabs(
            labels: const ['All', 'New', 'Review'],
            selectedIndex: 0,
            onChanged: (i) => changed = i,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Review'));
    await tester.pump();
    expect(changed, 2);
  });
}
