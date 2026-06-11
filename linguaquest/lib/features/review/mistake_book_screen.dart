import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            if (lessonMistakes.isEmpty && weakWords.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: l10n.mistakeBookCleared,
                message: l10n.mistakeBookClearedMsg,
                action: OutlinedButton.icon(
                  onPressed: () => context.go('/learn'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.commonContinue),
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
                const SizedBox(height: 10),
                for (final mistake in lessonMistakes)
                  _MistakeWordRow(mistake: mistake, l10n: l10n),
                const SizedBox(height: 18),
              ],
              if (weakWords.isNotEmpty) ...[
                Text(
                  '弱项生词',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ImageCueBadge(cue: mistake.word.imageCue, size: 56),
          const SizedBox(width: 12),
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
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => word.source == 'target'
              ? context.push('/wordbook/${word.sourceWordId ?? word.id}')
              : context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        word.meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
