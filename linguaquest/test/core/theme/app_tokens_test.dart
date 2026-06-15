import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';

Future<T> _readWithBrightness<T>(
  WidgetTester tester,
  Brightness brightness,
  T Function(BuildContext) read,
) async {
  late T value;
  await tester.pumpWidget(
    Theme(
      data: ThemeData(brightness: brightness),
      child: Builder(
        builder: (c) {
          value = read(c);
          return const SizedBox();
        },
      ),
    ),
  );
  return value;
}

void main() {
  testWidgets('cardShadow is present in light mode', (tester) async {
    final shadow = await _readWithBrightness(
      tester,
      Brightness.light,
      AppTokens.cardShadow,
    );
    expect(shadow, isNotEmpty);
  });

  testWidgets('cardShadow is empty in dark mode', (tester) async {
    final shadow = await _readWithBrightness(
      tester,
      Brightness.dark,
      AppTokens.cardShadow,
    );
    expect(shadow, isEmpty);
  });

  testWidgets('semantic accents brighten on dark', (tester) async {
    final light = await _readWithBrightness(
      tester,
      Brightness.light,
      AppTokens.successColor,
    );
    final dark = await _readWithBrightness(
      tester,
      Brightness.dark,
      AppTokens.successColor,
    );
    expect(light, isNot(equals(dark)));
  });
}
