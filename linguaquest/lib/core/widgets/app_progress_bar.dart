import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Horizontal progress bar with a sunken track.
///
/// By default the fill uses the mango→success gradient. Set [solid] to render a
/// flat azure fill instead (the cool-blue reference comps use solid progress
/// bars); pass [solidColor] to override the solid hue.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = 9,
    this.solid = false,
    this.solidColor,
    super.key,
  });

  /// 0..1; clamped for layout.
  final double value;
  final double height;

  /// When true, paints a flat color fill rather than the mango→success gradient.
  final bool solid;

  /// Solid fill color (defaults to brand azure). Only used when [solid] is true.
  final Color? solidColor;

  @override
  Widget build(BuildContext context) {
    final factor = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: Container(
        height: height,
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : AppTokens.surfaceSunken,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: factor,
          child: Container(
            decoration: BoxDecoration(
              color: solid ? (solidColor ?? AppTokens.azure) : null,
              gradient: solid ? null : AppTokens.progressGradient,
            ),
          ),
        ),
      ),
    );
  }
}
