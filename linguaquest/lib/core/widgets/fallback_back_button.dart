import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FallbackBackButton extends StatelessWidget {
  const FallbackBackButton({required this.fallbackLocation, super.key});

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(fallbackLocation);
      },
    );
  }
}
