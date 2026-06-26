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

  test('light theme chip labels are readable, not washed-out light', () {
    final theme = AppTheme.light();
    final labelStyle = theme.chipTheme.labelStyle;
    expect(labelStyle, isA<WidgetStateTextStyle>());
    final resolvable = labelStyle as WidgetStateTextStyle;
    final unselected = resolvable.resolve(<WidgetState>{});
    final selected = resolvable.resolve(<WidgetState>{WidgetState.selected});
    // Unselected label: dark navy ink, clearly readable on a light card.
    expect(unselected.color, AppTokens.textPrimaryLight);
    expect(unselected.color!.computeLuminance(), lessThan(0.4));
    // Selected label: strong primary emphasis, never a faint light color.
    expect(selected.color, theme.colorScheme.primary);
    expect(selected.color!.computeLuminance(), lessThan(0.5));
    // A concrete font size must be carried so the color actually applies
    // (a bare TextStyle(color:) can be dropped by the chip's default merge).
    expect(unselected.fontSize, isNotNull);
  });
}
