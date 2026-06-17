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
}
