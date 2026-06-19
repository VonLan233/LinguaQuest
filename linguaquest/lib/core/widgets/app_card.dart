import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Standard white content card: warm single-layer shadow, [radiusCard] corners.
///
/// When [onTap] is provided the card becomes tappable with a visible ink
/// ripple. The shadow lives on an outer [Container] (transparent fill) while
/// the surface fill, corner clipping, and ripple all live on an inner
/// [Material]/[InkWell] so the splash paints above the fill rather than under
/// it.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s16),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTokens.radiusCard);
    final surface = Theme.of(context).colorScheme.surface;
    final padded = Padding(padding: padding, child: child);

    // Outer container carries only the soft shadow + rounded silhouette.
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppTokens.cardShadow(context),
      ),
      child: Material(
        color: surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? padded
            : InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: padded,
              ),
      ),
    );
  }
}
