import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final query = _query.trim().toLowerCase();
    final targetWords = state.lessons
        .expand((lesson) => lesson.words)
        .where((word) => _matchesTargetWord(word, query))
        .toList();
    final customWords = state.customWords
        .where((word) => _matchesCustomWord(word, query))
        .toList();
    final hasQuery = query.isNotEmpty;
    final hasResults = targetWords.isNotEmpty || customWords.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('搜索'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '搜索单词、释义、例句或标签',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (!hasQuery)
              const EmptyState(
                icon: Icons.search,
                title: '输入关键词开始搜索',
                message: '可以搜索目标词、自定义词卡、中文释义、例句或标签。',
              )
            else if (!hasResults)
              EmptyState(
                icon: Icons.manage_search_outlined,
                title: '没有找到结果',
                message: '换一个关键词，或添加一张自定义词卡。',
                action: OutlinedButton.icon(
                  onPressed: () => context.push('/custom-words/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('添加自定义词'),
                ),
              )
            else ...[
              if (targetWords.isNotEmpty) ...[
                _SearchSectionTitle(title: '目标词', count: targetWords.length),
                for (final word in targetWords.take(20))
                  _TargetWordTile(word: word),
              ],
              if (customWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SearchSectionTitle(title: '自定义词卡', count: customWords.length),
                for (final word in customWords.take(20))
                  _CustomWordTile(word: word),
              ],
            ],
          ],
        ),
      ),
    );
  }

  bool _matchesTargetWord(Word word, String query) {
    if (query.isEmpty) return false;
    return word.word.toLowerCase().contains(query) ||
        word.meaning.toLowerCase().contains(query) ||
        word.definition.toLowerCase().contains(query) ||
        word.exampleSentence.toLowerCase().contains(query) ||
        word.exampleTranslation.toLowerCase().contains(query) ||
        word.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  bool _matchesCustomWord(CustomWord word, String query) {
    if (query.isEmpty) return false;
    return word.word.toLowerCase().contains(query) ||
        word.meaning.toLowerCase().contains(query) ||
        word.exampleSentence.toLowerCase().contains(query) ||
        word.note.toLowerCase().contains(query) ||
        word.tag.toLowerCase().contains(query);
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
  const _TargetWordTile({required this.word});

  final Word word;

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
                PillLabel(
                  label: displayDifficulty(word.difficulty),
                  color: AppTheme.coral,
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
  const _CustomWordTile({required this.word});

  final CustomWord word;

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
                        '${displayDifficulty(word.difficulty)} · ${word.tag}',
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
