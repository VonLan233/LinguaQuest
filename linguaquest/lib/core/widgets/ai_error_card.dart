import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_button.dart';

/// Persistent error card for AI screens.
///
/// Shows a warning icon, an error [message], and a Retry button that calls
/// [onRetry]. Built from Cozy Quest primitives ([AppCard], [AppPrimaryButton]).
class AiErrorCard extends StatelessWidget {
  const AiErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            AppIcons.warningAmber,
            size: 32,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.s16),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: l10n.commonRetry,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
