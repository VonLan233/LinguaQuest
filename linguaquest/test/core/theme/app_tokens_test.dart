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
  test('neutral tokens are locked (cool off-white page bg)', () {
    expect(
      AppTokens.bgLight,
      const Color(0xFFF7F9FC),
    ); // cool off-white page bg
    expect(AppTokens.surfaceLight, const Color(0xFFFFFFFF)); // cards stay white
    expect(AppTokens.surfaceSunken, const Color(0xFFEDF1F7));
    expect(AppTokens.hairline, const Color(0xFFE5EBF3));
    expect(AppTokens.textPrimaryLight, const Color(0xFF193956));
    expect(AppTokens.textSecondaryLight, const Color(0xFF64788B));
    expect(AppTokens.textHintLight, const Color(0xFF73869A));
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
    expect(AppTokens.radiusCard, 22);
    expect(AppTokens.radiusButton, 18);
    expect(AppTokens.radiusTile, 18);
    expect(AppTokens.radiusChip, 12);
  });

  test('progressGradient runs mango -> success', () {
    expect(AppTokens.progressGradient.colors.first, AppTokens.mango);
    expect(AppTokens.progressGradient.colors.last, AppTokens.success);
  });

  testWidgets('cardShadow present in light, empty in dark', (tester) async {
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
    expect(light, isNotEmpty);
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
