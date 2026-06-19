import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/stat_tile.dart';
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
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
            88,
          ),
          children: [
            _ReviewStatusHeader(
              isPaused: state.isStudyPlanPaused,
              dueCount: due.length,
              hiddenDueCount: hiddenDueCount,
              dailyReviewLimit: state.dailyReviewLimit,
              l10n: l10n,
            ),
            const SizedBox(height: AppTokens.s16),
            _ReviewQueueSignals(
              dueCount: due.length,
              weakCount: weak.length,
              cardCount: state.customWords.length,
              l10n: l10n,
            ),
            const SizedBox(height: AppTokens.s24),
            Text(
              l10n.reviewCenterTodayDue,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (due.isEmpty)
              MascotEmptyState(
                title: l10n.reviewCenterTodayDone,
                message: l10n.reviewCenterEmpty,
                action: AppSecondaryButton(
                  label: l10n.wordbookAddCustom,
                  onPressed: () => context.push('/custom-words/new'),
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
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: StatTile(
              value: '$dueCount',
              label: l10n.reviewCenterTodayDue,
              icon: AppIcons.today,
              accent: AppTokens.azure,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Flexible(
            child: StatTile(
              value: '$weakCount',
              label: l10n.mistakeBookTitle,
              icon: AppIcons.warningAmber,
              accent: AppTokens.coral,
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Flexible(
            child: StatTile(
              value: '$cardCount',
              label: l10n.commonCustomWords,
              icon: AppIcons.style,
              accent: AppTokens.azure,
            ),
          ),
        ],
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
    final localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: AppCard(
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
                        '${customWordMeaningFor(word, localeCode)} · ${formatRelativeDue(word.nextReviewAt, DateTime.now(), l10n)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppPill(
                  label: '${word.masteryLevel}/5',
                  icon: AppIcons.psychology,
                  variant: word.masteryLevel >= 3
                      ? PillVariant.success
                      : PillVariant.streak,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: l10n.reviewCenterForgot,
                    onPressed: canReview
                        ? () => _review(context, ref, isCorrect: false)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppPrimaryButton(
                    label: l10n.reviewCenterRemembered,
                    icon: AppIcons.check,
                    onPressed: canReview
                        ? () => _review(context, ref, isCorrect: true)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: AppCard(
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
            AppPill(
              label: l10n.commonLesson,
              icon: AppIcons.school,
              variant: PillVariant.streak,
            ),
          ],
        ),
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
    final localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => word.source == 'target'
            ? context.push('/wordbook/${word.sourceWordId ?? word.id}')
            : context.push('/custom-words/${word.id}'),
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
                    customWordMeaningFor(word, localeCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRight),
          ],
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
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: AppCard(
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
                icon: const Icon(AppIcons.addCard),
                label: Text(
                  '${widget.l10n.reviewCenterAddSelected} ($selectedAddableCount)',
                ),
              ),
          ],
        ),
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
    final color = selected ? AppTokens.azure : theme.colorScheme.outline;
    return Semantics(
      button: true,
      checked: selected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
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
                        ? AppTokens.primarySoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color, width: selected ? 2 : 1),
                  ),
                  child: Icon(
                    selected ? AppIcons.check : AppIcons.add,
                    color: selected ? AppTokens.azure : color,
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
                  const AppPill(
                    label: 'Added',
                    icon: AppIcons.checkCircle,
                    variant: PillVariant.success,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
