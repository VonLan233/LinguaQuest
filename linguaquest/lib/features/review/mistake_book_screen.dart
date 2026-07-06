import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

class MistakeBookScreen extends ConsumerWidget {
  const MistakeBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final lessonMistakes = state.lastResult?.mistakes ?? const [];
    final weakWords = state.weakWords;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/review'),
        title: Text(l10n.mistakeBookTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s24,
          ),
          children: [
            if (lessonMistakes.isEmpty && weakWords.isEmpty)
              MascotEmptyState(
                title: l10n.mistakeBookCleared,
                message: l10n.mistakeBookClearedMsg,
                action: AppSecondaryButton(
                  onPressed: () => context.go('/learn'),
                  icon: AppIcons.playArrow,
                  label: l10n.commonContinue,
                ),
              )
            else ...[
              if (lessonMistakes.isNotEmpty) ...[
                Text(
                  l10n.mistakeBookLessonMistakes,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                for (final mistake in lessonMistakes)
                  _MistakeWordRow(mistake: mistake, l10n: l10n),
                const SizedBox(height: AppTokens.s20),
              ],
              if (weakWords.isNotEmpty) ...[
                Text(
                  l10n.mistakeBookWeakWords,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                for (final word in weakWords)
                  _WeakCustomWordRow(word: word, l10n: l10n),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MistakeWordRow extends StatelessWidget {
  const _MistakeWordRow({required this.mistake, required this.l10n});

  final QuizQuestion mistake;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: AppCard(
        child: Row(
          children: [
            ImageCueBadge(cue: mistake.word.imageCue, size: 52),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mistake.word.word, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    mistake.explanation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            // Flexible lets the pill shrink (its text ellipsizes) under tight
            // width so the Explain-with-AI button below never gets pushed out
            // of the visible/tappable area. See SVV D-09.
            Flexible(
              child: AppPill(
                label: l10n.mistakeBookLessonMistakes,
                variant: PillVariant.streak,
              ),
            ),
            IconButton(
              icon: const Icon(AppIcons.autoAwesome),
              tooltip: l10n.aiExplainWithAi,
              onPressed: () => context.push(
                '/ai-learning?word=${Uri.encodeComponent(mistake.word.word)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakCustomWordRow extends StatelessWidget {
  const _WeakCustomWordRow({required this.word, required this.l10n});

  final CustomWord word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: AppCard(
        onTap: () => word.source == 'target'
            ? context.push('/wordbook/${word.sourceWordId ?? word.id}')
            : context.push('/custom-words/${word.id}'),
        child: Row(
          children: [
            ImageCueBadge(cue: wordInitialCue(word.word), size: 52),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.word, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    customWordMeaningFor(word, localeCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            AppPill(
              label: l10n.mistakeBookWeakWords,
              variant: PillVariant.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
