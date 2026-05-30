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
    final radius = BorderRadius.circular(16);
    final decoration = BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(
        color:
            borderColor ??
            theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
      ),
      boxShadow: const [
        BoxShadow(
          color: AppTheme.cardShadow,
          blurRadius: 8,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 8,
            top: -2,
            child: _SubtleCatMark(
              color: scheme.primary.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentSurface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: PillLabel(label: badge!, color: scheme.secondary),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
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

class _SubtleCatMark extends StatelessWidget {
  const _SubtleCatMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(52, 24),
      painter: _SubtleCatMarkPainter(color),
    );
  }
}

class _SubtleCatMarkPainter extends CustomPainter {
  const _SubtleCatMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final leftEar = Path()
      ..moveTo(6, size.height)
      ..lineTo(16, 3)
      ..lineTo(27, size.height)
      ..close();
    final rightEar = Path()
      ..moveTo(25, size.height)
      ..lineTo(36, 3)
      ..lineTo(48, size.height)
      ..close();
    canvas.drawPath(leftEar, paint);
    canvas.drawPath(rightEar, paint);
  }

  @override
  bool shouldRepaint(covariant _SubtleCatMarkPainter oldDelegate) {
    return oldDelegate.color != color;
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
