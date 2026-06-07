import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 56, this.tooltip, this.onTap, super.key});

  final double size;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mark = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -size * 0.025,
          left: size * 0.2,
          child: _CornerTab(size: size),
        ),
        Positioned(
          top: -size * 0.025,
          right: size * 0.2,
          child: _CornerTab(size: size),
        ),
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.09),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(size * 0.26),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: (size * 0.025).clamp(1.0, 3.0),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.18),
            child: Image.asset(
              'lib/assets/image/icon_transparent.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );

    final child = onTap == null
        ? mark
        : InkWell(
            borderRadius: BorderRadius.circular(size * 0.3),
            onTap: onTap,
            child: mark,
          );

    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class _CornerTab extends StatelessWidget {
  const _CornerTab({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size * 0.16,
        height: size * 0.16,
        decoration: BoxDecoration(
          color: AppTheme.accentSurface(context),
          borderRadius: BorderRadius.circular(size * 0.035),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }
}
