import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/brand_hero_card.dart';

void main() {
  testWidgets('BrandHeroCard renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandHeroCard(child: Text('hero title')),
        ),
      ),
    );

    expect(find.text('hero title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
