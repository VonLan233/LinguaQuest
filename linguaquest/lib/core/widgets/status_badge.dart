import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Semantic tone for a [StatusBadge].
enum StatusTone { neutral, info, success, warning, danger }

/// A small pill conveying a status with a tone-tinted background and matching
/// text/icon color.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  Color _toneColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (tone) {
      case StatusTone.danger:
        return AppTokens.coralColor(context);
      case StatusTone.warning:
        return AppTokens.amberColor(context);
      case StatusTone.success:
        return AppTokens.successColor(context);
      case StatusTone.info:
        return colorScheme.primary;
      case StatusTone.neutral:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppTokens.s4),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
