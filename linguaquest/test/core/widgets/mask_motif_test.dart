import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/mask_motif.dart';

void main() {
  testWidgets('MaskBackdrop renders without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MaskBackdrop()),
      ),
    );

    expect(find.byType(MaskBackdrop), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MaskBackdrop overlays its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MaskBackdrop(child: Center(child: Text('overlay'))),
        ),
      ),
    );

    expect(find.text('overlay'), findsOneWidget);
  });
}
