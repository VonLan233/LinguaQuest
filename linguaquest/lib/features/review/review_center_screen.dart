import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

class ReviewCenterScreen extends ConsumerWidget {
  const ReviewCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final due = state.isStudyPlanPaused
        ? const <CustomWord>[]
        : state.reviewQueue;
    final totalDue = state.isStudyPlanPaused ? 0 : state.dueWords.length;
    final weak = state.weakWords;
    final lessonMistakes = state.lastResult?.mistakes ?? const [];
    final hiddenDueCount = (totalDue - due.length).clamp(0, 9999).toInt();

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.reviewCenterTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
          children: [
            _ReviewStatusHeader(
              isPaused: state.isStudyPlanPaused,
              dueCount: due.length,
              hiddenDueCount: hiddenDueCount,
              dailyReviewLimit: state.dailyReviewLimit,
              l10n: l10n,
            ),
            const SizedBox(height: 16),
            _ReviewQueueSignals(
              dueCount: due.length,
              weakCount: weak.length,
              cardCount: state.customWords.length,
              l10n: l10n,
            ),
            const SizedBox(height: 22),
            Text(
              l10n.reviewCenterTodayDue,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (due.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: l10n.reviewCenterEmpty,
                message: l10n.reviewCenterEmpty,
                action: OutlinedButton.icon(
                  onPressed: () => context.push('/custom-words/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.wordbookAddCustom),
                ),
              )
            else
              for (final word in due) _ReviewTile(word: word, l10n: l10n),
            const SizedBox(height: 22),
            if (lessonMistakes.isNotEmpty || weak.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.mistakeBookTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/mistake-book'),
                    child: Text(l10n.commonReview),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (lessonMistakes.isNotEmpty)
                _MistakeWordImporter(mistakes: lessonMistakes, l10n: l10n),
              for (final mistake in lessonMistakes.take(3))
                _LessonMistakeRow(mistake: mistake, l10n: l10n),
              for (final word in weak.take(3))
                _WeakWordRow(word: word, l10n: l10n),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewStatusHeader extends StatelessWidget {
  const _ReviewStatusHeader({
    required this.isPaused,
    required this.dueCount,
    required this.hiddenDueCount,
    required this.dailyReviewLimit,
    required this.l10n,
  });

  final bool isPaused;
  final int dueCount;
  final int hiddenDueCount;
  final int dailyReviewLimit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title;
    String? subtitle;

    if (isPaused) {
      title = l10n.reviewCenterPlanPaused;
      subtitle = l10n.reviewCenterPlanPausedHint;
    } else if (dueCount == 0) {
      title = l10n.reviewCenterTodayDone;
    } else {
      title = l10n.reviewCenterCardsDue(dueCount);
      if (hiddenDueCount > 0) {
        subtitle = l10n.reviewCenterDailyCap(dailyReviewLimit, hiddenDueCount);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ReviewQueueSignals extends StatelessWidget {
  const _ReviewQueueSignals({
    required this.dueCount,
    required this.weakCount,
    required this.cardCount,
    required this.l10n,
  });

  final int dueCount;
  final int weakCount;
  final int cardCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReviewSignal(
            label: l10n.reviewCenterTodayDue,
            value: '$dueCount',
            icon: Icons.today_outlined,
            color: AppTheme.teal,
          ),
        ),
        const _ReviewSignalDivider(),
        Expanded(
          child: _ReviewSignal(
            label: l10n.mistakeBookTitle,
            value: '$weakCount',
            icon: Icons.warning_amber_outlined,
            color: AppTheme.coral,
          ),
        ),
        const _ReviewSignalDivider(),
        Expanded(
          child: _ReviewSignal(
            label: l10n.commonCustomWords,
            value: '$cardCount',
            icon: Icons.style_outlined,
            color: AppTheme.cyan,
          ),
        ),
      ],
    );
  }
}

class _ReviewSignal extends StatelessWidget {
  const _ReviewSignal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSignalDivider extends StatelessWidget {
  const _ReviewSignalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: VerticalDivider(
        width: 16,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.word, required this.l10n});

  final CustomWord word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      appControllerProvider.select((state) => state.isLoading),
    );
    final canReview = word.isDue(DateTime.now()) && !isLoading;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageCueBadge(cue: wordInitialCue(word.word), size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.word, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      '${word.meaning} · ${formatRelativeDue(word.nextReviewAt, DateTime.now())}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PillLabel(
                label: '${word.masteryLevel}/5',
                icon: Icons.psychology_outlined,
                color: AppTheme.mango,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: canReview
                      ? () => _review(context, ref, isCorrect: false)
                      : null,
                  icon: const Icon(Icons.close),
                  label: FittedBox(child: Text(l10n.reviewCenterForgot)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: canReview
                      ? () => _review(context, ref, isCorrect: true)
                      : null,
                  icon: const Icon(Icons.check),
                  label: FittedBox(child: Text(l10n.reviewCenterRemembered)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref, {
    required bool isCorrect,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .reviewWord(word.id, isCorrect);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = succeeded
        ? isCorrect
              ? l10n.reviewCenterPostponedMessage
              : l10n.reviewCenterCloserReviewMessage
        : ref.read(appControllerProvider).errorMessage ??
              l10n.reviewCenterUpdateFailed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LessonMistakeRow extends StatelessWidget {
  const _LessonMistakeRow({required this.mistake, required this.l10n});

  final QuizQuestion mistake;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ImageCueBadge(cue: mistake.word.imageCue, size: 52),
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
          const SizedBox(width: 10),
          PillLabel(
            label: l10n.commonLesson,
            icon: Icons.school_outlined,
            color: AppTheme.coral,
          ),
        ],
      ),
    );
  }
}

class _WeakWordRow extends StatelessWidget {
  const _WeakWordRow({required this.word, required this.l10n});

  final CustomWord word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => word.source == 'target'
              ? context.push('/wordbook/${word.sourceWordId ?? word.id}')
              : context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 52),
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

class _MistakeWordImporter extends ConsumerStatefulWidget {
  const _MistakeWordImporter({required this.mistakes, required this.l10n});

  final List<QuizQuestion> mistakes;
  final AppLocalizations l10n;

  @override
  ConsumerState<_MistakeWordImporter> createState() =>
      _MistakeWordImporterState();
}

class _MistakeWordImporterState extends ConsumerState<_MistakeWordImporter> {
  static const _visibleMistakeLimit = 6;

  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = _visibleMistakeIds();
  }

  @override
  void didUpdateWidget(covariant _MistakeWordImporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.mistakes
        .take(_visibleMistakeLimit)
        .map((mistake) => mistake.word.id)
        .toSet();
    _selectedIds = _selectedIds.intersection(currentIds);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final visibleMistakes = widget.mistakes.take(_visibleMistakeLimit).toList();
    final existingWords = state.customWords
        .map((word) => word.word.trim().toLowerCase())
        .toSet();
    final selectableCount = visibleMistakes
        .where(
          (mistake) =>
              !existingWords.contains(mistake.word.word.trim().toLowerCase()),
        )
        .length;
    final selectedAddableCount = visibleMistakes
        .where(
          (mistake) =>
              _selectedIds.contains(mistake.word.id) &&
              !existingWords.contains(mistake.word.word.trim().toLowerCase()),
        )
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.l10n.reviewCenterAddMistakeCards,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            selectableCount == 0
                ? widget.l10n.mistakeBookNoLessonMistakes
                : widget.l10n.mistakeBookMistakes(selectableCount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final mistake in visibleMistakes) ...[
            Builder(
              builder: (context) {
                final exists = existingWords.contains(
                  mistake.word.word.trim().toLowerCase(),
                );
                return _MistakeSelectionRow(
                  key: ValueKey('mistake-select-${mistake.word.id}'),
                  word: mistake.word.word,
                  meaning: exists ? 'Already added' : mistake.word.meaning,
                  selected: !exists && _selectedIds.contains(mistake.word.id),
                  enabled: !exists,
                  onChanged: (checked) {
                    setState(() {
                      if (checked) {
                        _selectedIds.add(mistake.word.id);
                      } else {
                        _selectedIds.remove(mistake.word.id);
                      }
                    });
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          if (selectableCount > 0)
            FilledButton.icon(
              onPressed: selectedAddableCount == 0 || state.isLoading
                  ? null
                  : _addSelected,
              icon: const Icon(Icons.add_card_outlined),
              label: Text(
                '${widget.l10n.reviewCenterAddSelected} ($selectedAddableCount)',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addSelected() async {
    final added = await ref
        .read(appControllerProvider.notifier)
        .addMistakesToCustomWords(
          _selectedIds.intersection(_visibleMistakeIds()),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$added added')));
    if (added > 0) setState(() => _selectedIds.clear());
  }

  Set<String> _visibleMistakeIds() {
    return widget.mistakes
        .take(_visibleMistakeLimit)
        .map((mistake) => mistake.word.id)
        .toSet();
  }
}

class _MistakeSelectionRow extends StatelessWidget {
  const _MistakeSelectionRow({
    required this.word,
    required this.meaning,
    required this.selected,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String word;
  final String meaning;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppTheme.teal : theme.colorScheme.outline;
    return Semantics(
      button: true,
      checked: selected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onChanged(!selected) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.selectedSurface(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: selected ? 2 : 1),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    color: selected ? AppTheme.teal : color,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        meaning,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!enabled)
                  PillLabel(
                    label: 'Added',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.cyan,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
