import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';

/// Visual state for a [WordChoiceButton].
enum ChoiceState { idle, selected, correct, wrong }

/// A full-width tappable answer choice: a leading lettered chip plus the
/// option text. Appearance varies by [state].
///
/// When [state] is [ChoiceState.correct] or [ChoiceState.wrong], a result
/// icon is shown in the trailing position to provide non-color feedback for
/// accessibility. In high-contrast mode the border becomes heavier.
class WordChoiceButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final highContrast = ref.watch(
      appControllerProvider.select((s) => s.sensorySettings.highContrastMode),
    );
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
        accent = highContrast
            ? const Color(0xFF1B5E20) // deep green for high contrast
            : AppTokens.successColor(context);
      case ChoiceState.wrong:
        accent = highContrast
            ? const Color(0xFFB71C1C) // deep red for high contrast
            : AppTokens.coralColor(context);
    }

    final isIdle = state == ChoiceState.idle;
    final background = isIdle ? colorScheme.surface : accent.withValues(alpha: 0.12);
    final isTerminal =
        state == ChoiceState.correct || state == ChoiceState.wrong;
    final borderWidth = isIdle ? 1.0 : (highContrast && isTerminal ? 3.0 : 2.0);

    // Non-color feedback icon for correct/wrong states.
    Widget? trailingIcon;
    if (state == ChoiceState.correct) {
      trailingIcon = Icon(AppIcons.checkCircle, color: accent, size: 22);
    } else if (state == ChoiceState.wrong) {
      trailingIcon = Icon(AppIcons.cancel, color: accent, size: 22);
    }

    // Semantic label for screen readers.
    String semanticLabel = text;
    if (state == ChoiceState.correct) semanticLabel = '$text, correct';
    if (state == ChoiceState.wrong) semanticLabel = '$text, incorrect';

    final content = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: Border.all(
          color: accent,
          width: borderWidth,
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
          if (trailingIcon != null) ...[
            const SizedBox(width: AppTokens.s8),
            trailingIcon,
          ],
        ],
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: !isTerminal,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isTerminal ? null : onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      ),
    );
  }
}
