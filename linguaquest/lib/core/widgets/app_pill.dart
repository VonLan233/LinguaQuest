import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum PillVariant { xp, success, streak, primary, neutral }

/// Small semantic capsule badge (XP / streak / status).
class AppPill extends StatelessWidget {
  const AppPill({
    required this.label,
    this.variant = PillVariant.primary,
    this.icon,
    super.key,
  });

  final String label;
  final PillVariant variant;
  final IconData? icon;

  ({Color bg, Color fg}) get _colors => switch (variant) {
    PillVariant.xp => (bg: AppTokens.xpSoft, fg: AppTokens.xpSoftText),
    PillVariant.success => (
      bg: AppTokens.successSoft,
      fg: AppTokens.successSoftText,
    ),
    PillVariant.streak => (
      bg: AppTokens.streakSoft,
      fg: AppTokens.streakSoftText,
    ),
    PillVariant.primary => (
      bg: AppTokens.primarySoft,
      fg: AppTokens.primarySoftText,
    ),
    PillVariant.neutral => (
      bg: AppTokens.surfaceSunken,
      fg: AppTokens.textSecondaryLight,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = switch (variant) {
      PillVariant.xp => AppTokens.mangoColor(context),
      PillVariant.success => AppTokens.successColor(context),
      PillVariant.streak => AppTokens.coralColor(context),
      PillVariant.primary => theme.colorScheme.primary,
      PillVariant.neutral => theme.colorScheme.onSurfaceVariant,
    };
    final c = theme.brightness == Brightness.dark
        ? (bg: fg.withValues(alpha: .12), fg: fg)
        : _colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c.fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.fg,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
