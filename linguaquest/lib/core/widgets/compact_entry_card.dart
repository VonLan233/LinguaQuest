import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';

/// A flat entry row: an icon on the left, a single
/// title on the right, and an optional [trailing] widget (e.g. a status pill)
/// or an automatic chevron when the row navigates somewhere.
///
/// Deliberately has no description/subtitle — these rows replaced the taller
/// "icon + title + paragraph" cards so list screens stay scannable.
class CompactEntryCard extends StatelessWidget {
  const CompactEntryCard({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;

  /// Accent for the leading icon.
  final Color color;

  /// Optional right-hand widget (typically a status [AppPill]). When omitted
  /// and [onTap] is set on an enabled row, a navigation chevron is shown.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidget =
        trailing ??
        (enabled && onTap != null
            ? Icon(
                AppIcons.chevronRight,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null);

    final row = Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: AppTokens.s8),
          trailingWidget,
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: enabled ? row : Opacity(opacity: .6, child: row),
        ),
      ),
    );
  }
}
