import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A lightweight value + label pairing with an optional accent icon. Meant to
/// sit inside a panel or row, so it carries no card of its own.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.icon,
    this.accent,
    super.key,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = accent ?? colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: AppTokens.s12),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
