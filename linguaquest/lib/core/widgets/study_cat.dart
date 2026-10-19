import 'package:flutter/material.dart';

class StudyCat extends StatelessWidget {
  const StudyCat({this.size = 112, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'lib/assets/image/study_cat.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}
