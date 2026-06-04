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

class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final words = state.formalLessons.expand((lesson) => lesson.words).toList();
    final currentBook = state.currentWordBook;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('单词本'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: currentBook?.title ?? '图片单词本',
              subtitle: currentBook?.description ?? '用图片词卡串联发音、释义、例句、标签和复习信号。',
              trailing: QuestIconButton(
                tooltip: '生词本',
                onPressed: () => context.push('/custom-words'),
                icon: Icons.add_card_outlined,
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(
                  label: '${currentBook?.totalWords ?? words.length} 个目标词',
                  icon: Icons.style_outlined,
                  color: AppTheme.cyan,
                ),
                PillLabel(
                  label: '${state.wordBooks.length} 本词书',
                  icon: Icons.library_books_outlined,
                ),
                PillLabel(
                  label: '完成 ${(state.learningPathProgress * 100).round()}%',
                  icon: Icons.route_outlined,
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (state.wordBooks.isNotEmpty) ...[
              SectionHeader(
                title: '切换词书',
                subtitle: '当前词书会驱动首页、学习路径、搜索、训练场和复习入口。',
              ),
              const SizedBox(height: 12),
              _WordBookSwitcher(
                currentId: state.currentWordBookId,
                books: state.wordBooks,
                onSelect: (bookId) async {
                  final succeeded = await ref
                      .read(appControllerProvider.notifier)
                      .switchWordBook(bookId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(succeeded ? '已切换当前词书' : '暂时无法切换词书')),
                  );
                },
              ),
              const SizedBox(height: 22),
            ],
            SectionHeader(
              title: '目标词',
              subtitle:
                  '${words.length} 词 · 学习路径完成 ${(state.learningPathProgress * 100).round()}%',
            ),
            const SizedBox(height: 16),
            for (final word in words) _TargetWordRow(word: word),
          ],
        ),
      ),
    );
  }
}

class _WordBookSwitcher extends StatelessWidget {
  const _WordBookSwitcher({
    required this.currentId,
    required this.books,
    required this.onSelect,
  });

  final String currentId;
  final List<WordBook> books;
  final Future<void> Function(String bookId) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 132,
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
                          book.title,
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
                    book.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      PillLabel(label: book.examType),
                      PillLabel(label: '${book.totalWords} 词'),
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
                      Text(word.word, style: theme.textTheme.titleMedium),
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
