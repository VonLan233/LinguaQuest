import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'mascot_image.dart';

/// Empty-state block fronted by the blue-cat mascot for a consistent,
/// encouraging "companion" personality across the app.
class MascotEmptyState extends StatelessWidget {
  const MascotEmptyState({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s24,
          vertical: AppTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotImage(size: 96),
            const SizedBox(height: AppTokens.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppTokens.s20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
