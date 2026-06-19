import 'package:flutter/material.dart';

/// The LinguaQuest blue-cat mascot. A single source so swapping the artwork
/// (or adding expression variants later) happens in one place.
class MascotImage extends StatelessWidget {
  const MascotImage({this.size = 72, super.key});

  final double size;

  static const String _asset = 'lib/assets/image/icon.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
