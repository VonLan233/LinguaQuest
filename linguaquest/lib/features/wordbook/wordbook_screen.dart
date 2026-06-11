import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/generated/app_localizations_zh.dart';

class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsZh();
    final state = ref.watch(appControllerProvider);
    final words = state.formalLessons.expand((lesson) => lesson.words).toList();
    final currentBook = state.currentWordBook;
    final studyBook = state.currentStudyBook;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.wordbookTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: currentBook != null
                  ? displayWordbookTitle(currentBook.id, l10n: l10n)
                  : l10n.wordbookImageBook,
              subtitle: currentBook != null
                  ? displayWordbookDescription(currentBook.id, l10n: l10n)
                  : displayWordbookDescription(studyBook.id, l10n: l10n),
              trailing: QuestIconButton(
                tooltip: '生词本',
                onPressed: () => context.push('/custom-words'),
                icon: Icons.add_card_outlined,
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(height: 14),
            _StudyBookCoverLine(
              cover: studyBook.cover,
              totalWords: words.length,
              completedWords: state.completedLearningWords,
              progress: state.learningPathProgress,
              onOpenPlan: () => context.push('/settings/study-plan'),
              l10n: l10n,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(
                  label: l10n.wordbookTargetWords(
                    currentBook?.totalWords ?? words.length,
                  ),
                  icon: Icons.style_outlined,
                  color: AppTheme.cyan,
                ),
                PillLabel(
                  label: l10n.wordbookBookCount(state.wordBooks.length),
                  icon: Icons.library_books_outlined,
                ),
                PillLabel(
                  label: l10n.wordbookCompletion(
                    (state.learningPathProgress * 100).round(),
                  ),
                  icon: Icons.route_outlined,
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (state.wordBooks.isNotEmpty) ...[
              SectionHeader(
                title: l10n.wordbookSwitch,
                subtitle: l10n.wordbookSwitchDesc,
              ),
              const SizedBox(height: 12),
              _WordBookSwitcher(
                currentId: state.currentWordBookId,
                books: state.wordBooks,
                l10n: l10n,
                onSelect: (bookId) async {
                  final succeeded = await ref
                      .read(appControllerProvider.notifier)
                      .switchWordBook(bookId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 2),
                      content: Text(
                        succeeded
                            ? l10n.wordbookSwitched
                            : l10n.wordbookSwitchFailed,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
            ],
            SectionHeader(
              title: l10n.wordbookTargetSection,
              subtitle: l10n.wordbookTargetDesc(
                words.length,
                (state.learningPathProgress * 100).round(),
              ),
            ),
            const SizedBox(height: 16),
            for (final word in words) _TargetWordRow(word: word),
          ],
        ),
      ),
    );
  }
}

class _StudyBookCoverLine extends StatelessWidget {
  const _StudyBookCoverLine({
    required this.cover,
    required this.totalWords,
    required this.completedWords,
    required this.progress,
    required this.onOpenPlan,
    required this.l10n,
  });

  final String cover;
  final int totalWords;
  final int completedWords;
  final double progress;
  final VoidCallback onOpenPlan;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.teal.withValues(alpha: 0.14),
          child: Text(cover, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.wordbookWordsLearned(completedWords, totalWords)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: AppTheme.progressTrack(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.teal,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenPlan,
                icon: const Icon(Icons.tune_outlined),
                label: Text(l10n.wordbookSwitch),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WordBookSwitcher extends StatelessWidget {
  const _WordBookSwitcher({
    required this.currentId,
    required this.books,
    required this.l10n,
    required this.onSelect,
  });

  final String currentId;
  final List<WordBook> books;
  final AppLocalizations l10n;
  final Future<void> Function(String bookId) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final book = books[index];
          final selected = book.id == currentId;
          return SizedBox(
            width: 220,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                side: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 2 : 1,
                ),
                backgroundColor: selected
                    ? AppTheme.selectedSurface(context)
                    : theme.colorScheme.surface,
                padding: const EdgeInsets.all(14),
              ),
              onPressed: selected ? null : () => onSelect(book.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayWordbookTitle(book.id, l10n: l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_outline, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayWordbookDescription(book.id, l10n: l10n),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      PillLabel(label: book.examType),
                      PillLabel(label: '共 ${book.totalWords} 词'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: books.length,
      ),
    );
  }
}

class _TargetWordRow extends StatelessWidget {
  const _TargetWordRow({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/wordbook/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageCueBadge(cue: word.imageCue, size: 62),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.word.toLowerCase(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(word.meaning),
                      const SizedBox(height: 3),
                      Text(
                        '${word.phonetic} · ${word.partOfSpeech}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        word.exampleSentence,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PillLabel(
                      label: displayDifficulty(word.difficulty),
                      color: word.difficulty == 'Hard'
                          ? theme.colorScheme.error
                          : AppTheme.coral,
                    ),
                    if (word.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      PillLabel(label: displayWordTag(word.tags.first)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
