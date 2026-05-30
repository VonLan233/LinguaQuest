import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.gradient,
    this.color,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(24);
    final decoration = BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(
        color:
            borderColor ??
            theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      boxShadow: const [
        BoxShadow(
          color: AppTheme.cardShadow,
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 0,
          offset: Offset(0, 3),
        ),
      ],
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

class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.cyan, AppTheme.deepTeal, AppTheme.teal],
        stops: [0, 0.58, 1],
      ),
      borderColor: Colors.white.withValues(alpha: 0.18),
      child: Stack(
        children: [
          Positioned(
            right: -58,
            bottom: -78,
            child: Container(
              width: 186,
              height: 186,
              decoration: BoxDecoration(
                color: AppTheme.mango.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -28,
            top: -26,
            child: Icon(
              icon,
              size: 132,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.35,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ],
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3A8), Color(0xFFE9FFD9), Color(0xFFDDF3FF)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: theme.colorScheme.surface, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
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
