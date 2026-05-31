import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

class IconCueBadge extends StatelessWidget {
  const IconCueBadge({
    required this.icon,
    this.color = AppTheme.teal,
    this.size = 42,
    super.key,
  });

  final IconData icon;
  final Color color;
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
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class QuestIconButton extends StatelessWidget {
  const QuestIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = AppTheme.teal,
    this.size = 44,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: size * 0.48),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: color,
          disabledForegroundColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          backgroundColor: AppTheme.iconBadgeSurface(context),
          disabledBackgroundColor: theme.colorScheme.surfaceContainerLow,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.26),
          ),
        ),
      ),
    );
  }
}

class FilterPillButton extends StatelessWidget {
  const FilterPillButton({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color = AppTheme.teal,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedForeground = AppTheme.isDark(context)
        ? theme.colorScheme.onPrimaryContainer
        : AppTheme.ink;
    return Material(
      color: selected ? AppTheme.selectedSurface(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.36)
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? selectedForeground
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

String wordInitialCue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
