import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Horizontal progress bar with sunken track and mango→success gradient fill.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = 9,
    super.key,
  });

  /// 0..1; clamped for layout.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final factor = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: Container(
        height: height,
        color: AppTokens.surfaceSunken,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: factor,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppTokens.progressGradient,
            ),
          ),
        ),
      ),
    );
  }
}
