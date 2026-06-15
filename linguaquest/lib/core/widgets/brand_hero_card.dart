import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'mask_motif.dart';

/// A branded hero surface with a navy→azure gradient, a decorative mask motif
/// in the top-right corner, and white-by-default text for its child.
class BrandHeroCard extends StatelessWidget {
  const BrandHeroCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppTokens.radiusCard);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brandNavy, AppTokens.azure],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -AppTokens.s24,
            right: -AppTokens.s12,
            child: SizedBox(
              width: 140,
              child: MaskBackdrop(color: Colors.white, height: 120),
            ),
          ),
          Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
