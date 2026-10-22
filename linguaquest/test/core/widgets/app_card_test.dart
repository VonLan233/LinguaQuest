import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';
import 'package:linguaquest/core/widgets/app_card.dart';

void main() {
  testWidgets('AppCard renders child and applies card radius', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppCard(child: Text('hello'))),
      ),
    );

    expect(find.text('hello'), findsOneWidget);

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppTokens.radiusCard),
    );
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNotNull);
  });

  testWidgets('AppCard fires onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('tap me'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('tap me'));
    expect(tapped, isTrue);
  });

  testWidgets('AppCard adds an InkWell only when tappable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppCard(child: Text('static'))),
      ),
    );
    expect(
      find.descendant(of: find.byType(AppCard), matching: find.byType(InkWell)),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(onTap: () {}, child: const Text('tappable')),
        ),
      ),
    );
    expect(
      find.descendant(of: find.byType(AppCard), matching: find.byType(InkWell)),
      findsOneWidget,
    );
  });
}
