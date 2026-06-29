import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:linguaquest/core/theme/app_icons.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/utils/wordbook_progress.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/wordbook_cover_card.dart';
import '../../data/models/lesson.dart';
import '../../data/models/user_word.dart';
import '../../l10n/generated/app_localizations.dart';

/// Wordbook overview — rebuilt to the cool-blue reference design:
/// header → hero current-book card → horizontal book scroller → dense word list.
class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(appControllerProvider);
    final words = state.formalLessons.expand((lesson) => lesson.words).toList();
    final currentBook = state.currentWordBook;
    final studyBook = state.currentStudyBook;
    final plan = state.studyPlan;

    // Per-word user status lookup (status pill / favorite state).
    final userWordByWordId = <String, UserWord>{
      for (final uw in state.userWords) uw.wordId: uw,
    };

    final bookId = currentBook?.id ?? studyBook.id;
    final currentWordIds =
        currentBook?.wordIds.toSet() ?? words.map((word) => word.id).toSet();
    final completed = learnedWordCountForBook(
      userWords: state.userWords,
      wordBookId: bookId,
      wordIds: currentWordIds,
    );
    final total = currentBook?.totalWords ?? words.length;
    final progress = wordbookProgressValue(
      learnedWords: completed,
      totalWords: total,
    );
    final percent = (progress * 100).round();
    final bookName = currentBook != null
        ? currentBook.nameFor(localeCode)
        : studyBook.name;
    final examType = currentBook?.examType ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.wordbookTitle),
        actions: [
          IconButton(
            tooltip: l10n.wordbookSearchHint,
            icon: const Icon(AppIcons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: l10n.wordbookCustomTooltip,
            icon: const Icon(AppIcons.tune),
            onPressed: () => context.push('/custom-words'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s16,
          ),
          children: [
            _HeroBookCard(
              bookId: bookId,
              bookName: bookName,
              examType: examType,
              completed: completed,
              total: total,
              percent: percent,
              progress: progress,
              daysLeft: plan?.daysLeft(DateTime.now()),
              targetFinishDate: plan?.targetFinishDate,
              onEditPlan: () => context.push('/settings/study-plan'),
              l10n: l10n,
            ),
            const SizedBox(height: AppTokens.s16),
            if (state.wordBooks.isNotEmpty) ...[
              _BookScroller(
                books: state.wordBooks,
                currentId: state.currentWordBookId,
                localeCode: localeCode,
                l10n: l10n,
                userWords: state.userWords,
                onSelect: (id) => _switchBook(context, ref, l10n, id),
              ),
              const SizedBox(height: AppTokens.s20),
            ],
            _ListHeader(count: total, l10n: l10n),
            const SizedBox(height: AppTokens.s8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < words.length; i++) ...[
                    if (i > 0) const _RowDivider(),
                    _WordListRow(
                      index: i + 1,
                      word: words[i],
                      userWord: userWordByWordId[words[i].id],
                      localeCode: localeCode,
                      l10n: l10n,
                      onTap: () => context.push('/wordbook/${words[i].id}'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchBook(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String bookId,
  ) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .switchWordBook(bookId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          succeeded ? l10n.wordbookSwitched : l10n.wordbookSwitchFailed,
        ),
      ),
    );
  }
}

/// Hero card for the current book: programmatic cover + name + meta + progress.
class _HeroBookCard extends StatelessWidget {
  const _HeroBookCard({
    required this.bookId,
    required this.bookName,
    required this.examType,
    required this.completed,
    required this.total,
    required this.percent,
    required this.progress,
    required this.daysLeft,
    required this.targetFinishDate,
    required this.onEditPlan,
    required this.l10n,
  });

  final String bookId;
  final String bookName;
  final String examType;
  final int completed;
  final int total;
  final int percent;
  final double progress;
  final int? daysLeft;
  final DateTime? targetFinishDate;
  final VoidCallback onEditPlan;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WordbookCoverCard(
            examType: examType,
            bookId: bookId,
            title: bookName,
          ),
          const SizedBox(width: AppTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _EditPlanChip(
                    label: l10n.wordbookSwitch,
                    onTap: onEditPlan,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  bookName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  _metaLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$completed',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.azure,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('/'),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.wordbookTargetWords(total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percent%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.azure,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                AppProgressBar(value: progress, solid: true, height: 8),
                if (targetFinishDate != null) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    _dateKey(targetFinishDate!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _metaLine {
    final parts = <String>[];
    if (daysLeft != null) parts.add(l10n.studyPlanDaysLeft(daysLeft!));
    parts.add(l10n.wordbookCompletion(percent));
    return parts.join(' · ');
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EditPlanChip extends StatelessWidget {
  const _EditPlanChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppTokens.primarySoft,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.tune,
              size: 13,
              color: AppTokens.primarySoftText,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTokens.primarySoftText,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scroller of the available books as small cover cards.
class _BookScroller extends StatelessWidget {
  const _BookScroller({
    required this.books,
    required this.currentId,
    required this.localeCode,
    required this.l10n,
    required this.userWords,
    required this.onSelect,
  });

  final List<WordBook> books;
  final String currentId;
  final String localeCode;
  final AppLocalizations l10n;
  final List<UserWord> userWords;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTokens.s12),
        itemBuilder: (context, index) {
          final book = books[index];
          final selected = book.id == currentId;
          final learned = learnedWordCountForBook(
            userWords: userWords,
            wordBookId: book.id,
            wordIds: book.wordIds.toSet(),
          );
          final total = book.totalWords;
          final progress = wordbookProgressValue(
            learnedWords: learned,
            totalWords: total,
          );
          return GestureDetector(
            onTap: selected ? null : () => onSelect(book.id),
            child: Container(
              width: 112,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusTile + 4),
                border: Border.all(
                  color: selected ? AppTokens.azure : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WordbookCoverCard(
                    examType: book.examType,
                    bookId: book.id,
                    title: book.nameFor(localeCode),
                    width: 100,
                    height: 112,
                  ),
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    '$learned / $total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AppProgressBar(value: progress, solid: true, height: 5),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.count, required this.l10n});

  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          l10n.wordbookTargetSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Text(
          '($count)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppTokens.s12,
      endIndent: AppTokens.s12,
      color: Theme.of(context).dividerColor,
    );
  }
}

/// Dense word row: index · headword · audio · difficulty tag · star ·
/// phonetic/POS · localized meaning · example · status pill.
class _WordListRow extends StatelessWidget {
  const _WordListRow({
    required this.index,
    required this.word,
    required this.userWord,
    required this.localeCode,
    required this.l10n,
    required this.onTap,
  });

  final int index;
  final Word word;
  final UserWord? userWord;
  final String localeCode;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final meaning = word.primaryDefinitionFor(localeCode);
    final phoneticPos = [
      if (word.phonetic.isNotEmpty) word.phonetic,
      if (word.partOfSpeech.isNotEmpty) word.partOfSpeech,
    ].join(' · ');
    final favorite = userWord?.isFavorite ?? false;
    final status = userWord?.status;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                index.toString().padLeft(3, '0'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          word.word.toLowerCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Icon(AppIcons.volumeUp, size: 16, color: muted),
                      const SizedBox(width: AppTokens.s8),
                      _DifficultyTag(difficulty: word.difficulty, l10n: l10n),
                    ],
                  ),
                  if (phoneticPos.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s2),
                    Text(
                      phoneticPos,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                  if (meaning.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s2),
                    Text(meaning, style: theme.textTheme.bodyMedium),
                  ],
                  if (word.exampleSentence.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.s2),
                    Text(
                      word.exampleSentence,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  favorite ? AppIcons.star : AppIcons.starBorder,
                  size: 18,
                  color: favorite ? AppTokens.amber : muted,
                ),
                if (status != null) ...[
                  const SizedBox(height: AppTokens.s8),
                  _StatusPill(status: status, l10n: l10n),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyTag extends StatelessWidget {
  const _DifficultyTag({required this.difficulty, required this.l10n});

  final String difficulty;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (difficulty) {
      'Hard' => (AppTokens.dangerSoft, AppTokens.danger),
      'Medium' => (AppTokens.primarySoft, AppTokens.primarySoftText),
      _ => (AppTokens.surfaceSunken, AppTokens.textSecondaryLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Text(
        displayDifficulty(difficulty, l10n: l10n),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.l10n});

  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final variant = switch (status) {
      'Mastered' => PillVariant.success,
      'Review' || 'Relearning' => PillVariant.xp,
      'Learning' || 'Previewed' => PillVariant.primary,
      _ => PillVariant.neutral,
    };
    return AppPill(
      label: displayWordStatus(status, l10n: l10n),
      variant: variant,
    );
  }
}
