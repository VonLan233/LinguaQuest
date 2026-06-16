import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';
import 'package:linguaquest/core/widgets/app_button.dart';

void main() {
  testWidgets('AppPrimaryButton shows label and fires onPressed',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: '开始学习',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    expect(find.text('开始学习'), findsOneWidget);
    await tester.tap(find.byType(AppPrimaryButton));
    expect(pressed, isTrue);
  });

  testWidgets('AppPrimaryButton with null onPressed is disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(label: 'x', onPressed: null),
        ),
      ),
    );
    final gesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(AppPrimaryButton),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gesture.onTap, isNull);
  });

  testWidgets('AppPrimaryButton exposes an enabled button to a11y',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(label: 'go', onPressed: () {}),
        ),
      ),
    );
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(AppPrimaryButton),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.enabled, isTrue);
  });

  testWidgets('AppPrimaryButton mutes its label when disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(label: 'off', onPressed: null),
        ),
      ),
    );
    final label = tester.widget<Text>(find.text('off'));
    expect(label.style?.color, AppTokens.textHintLight);
  });

  testWidgets('AppSecondaryButton renders outlined label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSecondaryButton(label: '稍后', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('稍后'), findsOneWidget);
  });
}
