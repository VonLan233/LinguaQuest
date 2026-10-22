import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/app_button.dart';

void main() {
  testWidgets('AppPrimaryButton shows label and fires onPressed', (
    tester,
  ) async {
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

  testWidgets('AppPrimaryButton with null onPressed is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppPrimaryButton(label: 'x', onPressed: null)),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('AppPrimaryButton exposes an enabled button to a11y', (
    tester,
  ) async {
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

  testWidgets('AppPrimaryButton mutes its label when disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppPrimaryButton(label: 'off', onPressed: null)),
      ),
    );
    final label = tester.widget<Text>(find.text('off'));
    expect(
      label.style?.color,
      Theme.of(tester.element(find.text('off'))).colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('AppPrimaryButton constrains long labels', (tester) async {
    const label = 'Start Today With A Very Long Localized Label';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: AppPrimaryButton(
              label: label,
              icon: Icons.play_arrow,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(label));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
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

  testWidgets('AppSecondaryButton renders optional leading icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSecondaryButton(
            label: '收藏',
            icon: Icons.star_border_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('收藏'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
  });

  testWidgets('AppSecondaryButton constrains long labels', (tester) async {
    const label = 'Review Only With A Very Long Localized Label';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: AppSecondaryButton(
              label: label,
              icon: Icons.replay,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(label));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
