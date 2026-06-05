import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/dictionary_search.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  DictionarySearchScope _scope = DictionarySearchScope.currentWordBook;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final query = normalizeDictionaryQuery(_query);
    final targetWords = searchDictionaryWords(
      wordBooks: state.wordBooks,
      currentWordBookId: state.currentWordBookId,
      scope: _scope,
      query: query,
      currentWords: state.formalLessons
          .expand((lesson) => lesson.words)
          .toList(),
      tagLabeler: _displayTargetTag,
    );
    final customWords = searchCustomWords(
      customWords: state.customWords,
      query: query,
      tagLabeler: displayCustomTag,
    );
    final hasQuery = query.isNotEmpty;
    final hasResults = targetWords.isNotEmpty || customWords.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(state.currentWordBook?.title ?? '搜索'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '搜索单词、短语、中文释义或例句片段',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            _SearchScopeSelector(
              selected: _scope,
              currentBookTitle: state.currentWordBook?.title ?? '当前词书',
              onSelected: (scope) => setState(() => _scope = scope),
            ),
            const SizedBox(height: 16),
            if (!hasQuery)
              const EmptyState(
                icon: Icons.search,
                title: '输入关键词开始搜索',
                message: '可以搜索英文单词、词组、中文释义、例句片段和生词本。',
              )
            else if (!hasResults)
              EmptyState(
                icon: Icons.manage_search_outlined,
                title: '没有找到结果',
                message: '切到全词库再试，或添加一张个人词卡。',
                action: OutlinedButton.icon(
                  onPressed: () => context.push('/custom-words/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('添加生词'),
                ),
              )
            else ...[
              if (targetWords.isNotEmpty) ...[
                _SearchSectionTitle(
                  title: dictionaryScopeLabel(_scope),
                  count: targetWords.length,
                ),
                for (final result in targetWords.take(20))
                  _TargetWordTile(result: result),
              ],
              if (customWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SearchSectionTitle(title: '生词本', count: customWords.length),
                for (final result in customWords.take(20))
                  _CustomWordTile(result: result),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

String _displayTargetTag(String tag) => displayWordTag(tag);

class _SearchScopeSelector extends StatelessWidget {
  const _SearchScopeSelector({
    required this.selected,
    required this.currentBookTitle,
    required this.onSelected,
  });

  final DictionarySearchScope selected;
  final String currentBookTitle;
  final ValueChanged<DictionarySearchScope> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '搜索范围：$currentBookTitle / 全词库',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterPillButton(
              label: '当前词书',
              selected: selected == DictionarySearchScope.currentWordBook,
              onSelected: () =>
                  onSelected(DictionarySearchScope.currentWordBook),
            ),
            FilterPillButton(
              label: '全词库',
              selected: selected == DictionarySearchScope.allWordBooks,
              onSelected: () => onSelected(DictionarySearchScope.allWordBooks),
              color: AppTheme.cyan,
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 8),
          PillLabel(label: '$count', color: AppTheme.cyan),
        ],
      ),
    );
  }
}

class _TargetWordTile extends StatelessWidget {
  const _TargetWordTile({required this.result});

  final DictionaryWordSearchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = result.word;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                ImageCueBadge(cue: word.imageCue, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(word.meaning),
                      const SizedBox(height: 4),
                      Text(
                        '${result.matchedBy} · ${result.preview}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
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
                      color: AppTheme.coral,
                    ),
                    if (result.inCurrentWordBook) ...[
                      const SizedBox(height: 6),
                      const PillLabel(label: '当前计划', color: AppTheme.cyan),
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

class _CustomWordTile extends StatelessWidget {
  const _CustomWordTile({required this.result});

  final CustomWordSearchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = result.word;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(word.meaning),
                      const SizedBox(height: 4),
                      Text(
                        '${result.matchedBy} · ${result.preview}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${displayDifficulty(word.difficulty)} · ${displayCustomTag(word.tag)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
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
