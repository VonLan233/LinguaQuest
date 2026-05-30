import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(8);
    final decoration = BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      borderRadius: radius,
      border: Border.all(
        color:
            borderColor ??
            theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
      ),
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class PillLabel extends StatelessWidget {
  const PillLabel({
    required this.label,
    this.icon,
    this.color = AppTheme.teal,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final luminance = color.computeLuminance();
    final textColor = isDark
        ? (luminance < 0.3 ? theme.colorScheme.onSurface : color)
        : (luminance > 0.5 ? theme.colorScheme.onSurface : color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class ImageCueBadge extends StatelessWidget {
  const ImageCueBadge({required this.cue, this.size = 64, super.key});

  final String cue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.iconBadgeSurface(context),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(cue, style: TextStyle(fontSize: size * 0.48)),
    );
  }
}

String wordInitialCue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
