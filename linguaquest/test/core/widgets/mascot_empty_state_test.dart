import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/mascot_image.dart';
import 'package:linguaquest/core/widgets/mascot_empty_state.dart';

void main() {
  testWidgets('MascotEmptyState shows mascot, title, message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MascotEmptyState(
            title: '还没有错题',
            message: '继续学习，错词会自动收进来',
          ),
        ),
      ),
    );
    expect(find.byType(MascotImage), findsOneWidget);
    expect(find.text('还没有错题'), findsOneWidget);
    expect(find.text('继续学习，错词会自动收进来'), findsOneWidget);
  });

  testWidgets('MascotEmptyState renders optional action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MascotEmptyState(
            title: 't',
            message: 'm',
            action: FilledButton(onPressed: () {}, child: const Text('去学习')),
          ),
        ),
      ),
    );
    expect(find.text('去学习'), findsOneWidget);
  });
}
