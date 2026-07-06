import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/stat_tile.dart';

void main() {
  testWidgets('StatTile 在窄列中完整显示长标签', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            Expanded(
              child: StatTile(value: '12', label: 'Mastered', icon: Icons.star),
            ),
            Expanded(
              child: StatTile(value: '3', label: 'Review', icon: Icons.replay),
            ),
            Expanded(
              child: StatTile(value: '0', label: 'Learned', icon: Icons.school),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mastered'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Learned'), findsOneWidget);
    // 纵向布局下无 RenderFlex overflow（pumpAndSettle 不抛异常即通过）。
  });
}
