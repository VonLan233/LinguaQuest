import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_list_row.dart';
import '../../core/widgets/status_badge.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: QuestListRow(
        icon: Icons.school_outlined,
        iconColor: AppTokens.coralColor(context),
        title: mistake.word.word,
        subtitle: mistake.explanation,
        showChevron: false,
        trailing: StatusBadge(
          label: l10n.mistakeBookLessonMistakes,
          tone: StatusTone.danger,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: QuestListRow(
        icon: Icons.bolt_outlined,
        iconColor: AppTheme.mango,
        title: word.word,
        subtitle: word.meaning,
        trailing: StatusBadge(
          label: l10n.mistakeBookWeakWords,
          tone: StatusTone.warning,
        ),
        onTap: () => word.source == 'target'
            ? context.push('/wordbook/${word.sourceWordId ?? word.id}')
            : context.push('/custom-words/${word.id}'),
      ),
    );
  }
}
