import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Purely decorative cat-mask motif: two soft ear-like arcs joined by a
/// scalloped curve. Used as a subtle backdrop accent on branded surfaces.
class MaskBackdrop extends StatelessWidget {
  const MaskBackdrop({
    this.color,
    this.height = 120,
    this.child,
    super.key,
  });

  final Color? color;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTokens.sky;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: MaskMotifPainter(color: tint)),
          ?child,
        ],
      ),
    );
  }
}

/// Paints the twin-arc cat-mask silhouette at a low alpha.
class MaskMotifPainter extends CustomPainter {
  const MaskMotifPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.05, h * 0.95)
      // Left ear.
      ..cubicTo(w * 0.05, h * 0.30, w * 0.22, h * 0.05, w * 0.30, h * 0.40)
      // Scalloped dip between the ears.
      ..cubicTo(w * 0.40, h * 0.70, w * 0.60, h * 0.70, w * 0.70, h * 0.40)
      // Right ear.
      ..cubicTo(w * 0.78, h * 0.05, w * 0.95, h * 0.30, w * 0.95, h * 0.95)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MaskMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}
