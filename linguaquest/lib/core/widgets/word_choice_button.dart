import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Visual state for a [WordChoiceButton].
enum ChoiceState { idle, selected, correct, wrong }

/// A full-width tappable answer choice: a leading lettered chip plus the
/// option text. Appearance varies by [state].
class WordChoiceButton extends StatelessWidget {
  const WordChoiceButton({
    required this.letter,
    required this.text,
    this.state = ChoiceState.idle,
    this.onTap,
    super.key,
  });

  final String letter;
  final String text;
  final ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(AppTokens.radiusButton);

    late final Color accent;
    switch (state) {
      case ChoiceState.idle:
        accent = colorScheme.outline;
      case ChoiceState.selected:
        accent = colorScheme.primary;
      case ChoiceState.correct:
        accent = AppTokens.successColor(context);
      case ChoiceState.wrong:
        accent = AppTokens.coralColor(context);
    }

    final isIdle = state == ChoiceState.idle;
    final background = isIdle
        ? colorScheme.surface
        : accent.withValues(alpha: 0.12);
    final isTerminal =
        state == ChoiceState.correct || state == ChoiceState.wrong;

    final content = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: Border.all(
          color: accent,
          width: isIdle ? 1 : 2,
        ),
      ),
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isIdle
                  ? colorScheme.surfaceContainerHighest
                  : accent.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isIdle ? colorScheme.onSurfaceVariant : accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: isTerminal ? null : onTap,
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }
}
