import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';

void main() {
  test('light theme scaffold uses warm porcelain background', () {
    final theme = AppTheme.light();
    expect(theme.scaffoldBackgroundColor, AppTokens.bgLight);
  });

  test('light theme low surface container is warm, not cool blue', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.surfaceContainerLow, AppTokens.bgLight);
    expect(theme.colorScheme.surfaceContainerLowest, AppTokens.surfaceLight);
  });

  test('light theme high containers and outline use warm neutrals', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.surfaceContainerHigh, AppTokens.surfaceSunken);
    expect(theme.colorScheme.surfaceContainerHighest, const Color(0xFFE8E2D9));
    expect(theme.colorScheme.outline, AppTokens.hairline);
  });

  test('chip labels carry a concrete onSurface color (light + dark)', () {
    for (final pair in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      final labelStyle = pair.value.chipTheme.labelStyle;
      expect(labelStyle, isNotNull, reason: pair.key);
      // 普通 TextStyle，颜色受控为 onSurface（不再是 resolve 才有颜色的
      // WidgetStateTextStyle —— 那种在 ChoiceChip 上 color 解析为 null）。
      expect(labelStyle, isNot(isA<WidgetStateTextStyle>()), reason: pair.key);
      expect(labelStyle!.color, pair.value.colorScheme.onSurface,
          reason: pair.key);
      // 必须带具体字号，颜色才会被 chip 默认 merge 保留。
      expect(labelStyle.fontSize, isNotNull, reason: pair.key);
    }
  });
}
