import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/brand_hero_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/quest_list_row.dart';
import '../../core/widgets/quest_panel.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            SectionHeader(
              title: currentBook != null
                  ? displayWordbookTitle(currentBook.id, l10n: l10n)
                  : l10n.wordbookImageBook,
              subtitle: currentBook != null
                  ? displayWordbookDescription(currentBook.id, l10n: l10n)
                  : displayWordbookDescription(studyBook.id, l10n: l10n),
              trailing: QuestIconButton(
                tooltip: l10n.wordbookCustomTooltip,
                onPressed: () => context.push('/custom-words'),
                icon: Icons.add_card_outlined,
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            _StudyBookHero(
              cover: studyBook.cover,
              totalWords: words.length,
              completedWords: state.completedLearningWords,
              progress: state.learningPathProgress,
              onOpenPlan: () => context.push('/settings/study-plan'),
              l10n: l10n,
            ),
            const SizedBox(height: AppTokens.s16),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
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
            const SizedBox(height: AppTokens.s24),
            if (state.wordBooks.isNotEmpty) ...[
              SectionHeader(
                title: l10n.wordbookSwitch,
                subtitle: l10n.wordbookSwitchDesc,
              ),
              const SizedBox(height: AppTokens.s12),
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
              const SizedBox(height: AppTokens.s24),
            ],
            SectionHeader(
              title: l10n.wordbookTargetSection,
              subtitle: l10n.wordbookTargetDesc(
                words.length,
                (state.learningPathProgress * 100).round(),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            for (final word in words) _TargetWordRow(word: word, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _StudyBookHero extends StatelessWidget {
  const _StudyBookHero({
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
    return BrandHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                ),
                child: Text(cover, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: Text(
                  l10n.wordbookWordsLearned(completedWords, totalWords),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              ProgressRing(
                progress: progress,
                size: 64,
                strokeWidth: 7,
                color: Colors.white,
                centerLabel: '${(progress * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenPlan,
              icon: const Icon(Icons.tune_outlined),
              label: Text(l10n.wordbookSwitch),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
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
    final selectedIndex = books.indexWhere((book) => book.id == currentId);
    final activeIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final selectedBook = books[activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedTabs(
          labels: [
            for (final book in books)
              displayWordbookTitle(book.id, l10n: l10n),
          ],
          selectedIndex: activeIndex,
          onChanged: (index) {
            final book = books[index];
            if (book.id == currentId) return;
            onSelect(book.id);
          },
        ),
        const SizedBox(height: AppTokens.s12),
        QuestPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayWordbookDescription(selectedBook.id, l10n: l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  PillLabel(label: selectedBook.examType),
                  PillLabel(
                    label: l10n.wordbookTotalWords(selectedBook.totalWords),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetWordRow extends StatelessWidget {
  const _TargetWordRow({required this.word, required this.l10n});

  final Word word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isHard = word.difficulty == 'Hard';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: QuestListRow(
        icon: Icons.menu_book_outlined,
        iconColor: isHard ? AppTokens.coralColor(context) : AppTheme.cyan,
        title: word.word.toLowerCase(),
        subtitle:
            '${word.meaning}\n${word.phonetic} · ${word.partOfSpeech}',
        onTap: () => context.push('/wordbook/${word.id}'),
        showChevron: false,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(
              label: displayDifficulty(word.difficulty),
              tone: isHard ? StatusTone.danger : StatusTone.info,
            ),
            if (word.tags.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s4),
              StatusBadge(
                label: displayWordTag(word.tags.first),
                tone: StatusTone.neutral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
