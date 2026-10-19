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
  test('neutral tokens are locked (neutral Swiss page background)', () {
    expect(
      AppTokens.bgLight,
      const Color(0xFFFAFBFC),
    ); // neutral Swiss page background
    expect(AppTokens.surfaceLight, const Color(0xFFFFFFFF)); // cards stay white
    expect(AppTokens.surfaceSunken, const Color(0xFFEEF0F3));
    expect(AppTokens.hairline, const Color(0xFFDDE1E6));
    expect(AppTokens.textPrimaryLight, const Color(0xFF171B22));
    expect(AppTokens.textSecondaryLight, const Color(0xFF535E6B));
    expect(AppTokens.textHintLight, const Color(0xFF626E7D));
  });

  test('semantic soft tokens exist', () {
    expect(AppTokens.xpSoft, const Color(0xFFFFF1D6));
    expect(AppTokens.successSoft, const Color(0xFFF2FAEC));
    expect(AppTokens.streakSoft, const Color(0xFFFFE2DC));
    expect(AppTokens.primarySoft, const Color(0xFFEAF2FC));
  });

  test('danger tokens are locked (true antonym/error red)', () {
    expect(AppTokens.danger, const Color(0xFFE5484D));
    expect(AppTokens.dangerSoft, const Color(0xFFFCE9EA));
  });

  test('radii match spec', () {
    expect(AppTokens.radiusCard, 4);
    expect(AppTokens.radiusButton, 4);
    expect(AppTokens.radiusTile, 4);
    expect(AppTokens.radiusChip, 4);
  });

  test('progressGradient runs mango -> success', () {
    expect(AppTokens.progressGradient.colors.first, AppTokens.mango);
    expect(AppTokens.progressGradient.colors.last, AppTokens.success);
  });

  testWidgets('flat surfaces have no shadow in either theme', (tester) async {
    final light = await _readWithBrightness(
      tester,
      Brightness.light,
      AppTokens.cardShadow,
    );
    final dark = await _readWithBrightness(
      tester,
      Brightness.dark,
      AppTokens.cardShadow,
    );
    expect(light, isEmpty);
    expect(dark, isEmpty);
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
