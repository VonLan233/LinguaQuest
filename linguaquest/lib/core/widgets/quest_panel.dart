import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A rounded surface panel with the shared soft card shadow. Optionally
/// tappable; the ripple clips to the rounded corners.
class QuestPanel extends StatelessWidget {
  const QuestPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s16),
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppTokens.radiusCard);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: borderRadius,
        boxShadow: AppTokens.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
