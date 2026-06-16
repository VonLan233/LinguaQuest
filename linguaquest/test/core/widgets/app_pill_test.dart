import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';
import 'package:linguaquest/core/widgets/app_pill.dart';

void main() {
  testWidgets('AppPill renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPill(label: '+126 XP', variant: PillVariant.xp),
        ),
      ),
    );
    expect(find.text('+126 XP'), findsOneWidget);
  });

  testWidgets('AppPill xp variant uses xpSoft background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPill(label: 'XP', variant: PillVariant.xp),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppPill),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppTokens.xpSoft);
  });

  testWidgets('every variant maps to its soft background and text color',
      (tester) async {
    final cases = <(PillVariant, Color, Color)>[
      (PillVariant.xp, AppTokens.xpSoft, AppTokens.xpSoftText),
      (PillVariant.success, AppTokens.successSoft, AppTokens.successSoftText),
      (PillVariant.streak, AppTokens.streakSoft, AppTokens.streakSoftText),
      (PillVariant.primary, AppTokens.primarySoft, AppTokens.primarySoftText),
    ];

    for (final (variant, bg, fg) in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPill(label: variant.name, variant: variant),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppPill),
          matching: find.byType(Container),
        ),
      );
      expect(
        (container.decoration as BoxDecoration).color,
        bg,
        reason: 'background for $variant',
      );

      final text = tester.widget<Text>(find.text(variant.name));
      expect(text.style?.color, fg, reason: 'text color for $variant');
    }
  });
}
