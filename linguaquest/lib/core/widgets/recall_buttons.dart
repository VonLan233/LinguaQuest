import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A row of three spaced-repetition recall buttons: unknown (coral),
/// fuzzy (amber) and known (success).
class RecallButtons extends StatelessWidget {
  const RecallButtons({
    required this.unknownLabel,
    required this.fuzzyLabel,
    required this.knownLabel,
    required this.onUnknown,
    required this.onFuzzy,
    required this.onKnown,
    super.key,
  });

  final String unknownLabel;
  final String fuzzyLabel;
  final String knownLabel;
  final VoidCallback onUnknown;
  final VoidCallback onFuzzy;
  final VoidCallback onKnown;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RecallButton(
            label: unknownLabel,
            color: AppTokens.coralColor(context),
            onTap: onUnknown,
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: _RecallButton(
            label: fuzzyLabel,
            color: AppTokens.amberColor(context),
            onTap: onFuzzy,
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: _RecallButton(
            label: knownLabel,
            color: AppTokens.successColor(context),
            onTap: onKnown,
          ),
        ),
      ],
    );
  }
}

class _RecallButton extends StatelessWidget {
  const _RecallButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppTokens.radiusButton);
    return Material(
      color: color,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s12,
            vertical: AppTokens.s12,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
