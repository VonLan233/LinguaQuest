import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Quiet bordered surface with an optional native ink interaction.
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Material(
        color: surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? padded
            : InkWell(borderRadius: radius, onTap: onTap, child: padded),
      ),
    );
  }
}
