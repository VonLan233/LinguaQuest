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
import '../../data/models/word_entry.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  List<WordEntry> _apiResults = [];
  var _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final query = _query.trim().toLowerCase();
    final targetWords = state.formalLessons
        .expand((lesson) => lesson.words)
        .where((word) => _matchesTargetWord(word, query))
        .toList();
    final customWords = state.customWords
        .where((word) => _matchesCustomWord(word, query))
        .toList();
    final hasQuery = query.isNotEmpty;
    final hasResults = targetWords.isNotEmpty || customWords.isNotEmpty || _apiResults.isNotEmpty;

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
              onChanged: (value) {
                setState(() {
                  _query = value;
                  _apiResults = [];
                });
              },
            ),
            const SizedBox(height: 16),
            if (!hasQuery)
              const EmptyState(
                icon: Icons.search,
                title: '输入关键词开始搜索',
                message: '可以搜索目标词、生词本、中文释义、例句或标签。',
              )
            else if (!hasResults && !_isSearching)
              EmptyState(
                icon: Icons.manage_search_outlined,
                title: '没有找到结果',
                message: '本地未找到匹配，可搜索完整词库。',
                action: FilledButton.icon(
                  onPressed: () => _searchApi(query),
                  icon: const Icon(Icons.language),
                  label: const Text('搜索完整词库'),
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
                _SearchSectionTitle(title: '生词本', count: customWords.length),
                for (final word in customWords.take(20))
                  _CustomWordTile(word: word),
              ],
              if (_apiResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SearchSectionTitle(title: '词库', count: _apiResults.length),
                for (final entry in _apiResults.take(20))
                  _WordEntryTile(entry: entry),
              ],
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _searchApi(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final controller = ref.read(appControllerProvider.notifier);
    final results = await controller.searchWords(query);
    if (mounted) {
      setState(() {
        _apiResults = results;
        _isSearching = false;
      });
    }
  }

  bool _matchesTargetWord(Word word, String query) {
    if (query.isEmpty) return false;
    return word.word.toLowerCase().contains(query) ||
        word.meaning.toLowerCase().contains(query) ||
        word.definition.toLowerCase().contains(query) ||
        word.exampleSentence.toLowerCase().contains(query) ||
        word.exampleTranslation.toLowerCase().contains(query) ||
        word.tags.any(
          (tag) =>
              tag.toLowerCase().contains(query) ||
              displayWordTag(tag).toLowerCase().contains(query),
        );
  }

  bool _matchesCustomWord(CustomWord word, String query) {
    if (query.isEmpty) return false;
    return word.word.toLowerCase().contains(query) ||
        word.meaning.toLowerCase().contains(query) ||
        word.exampleSentence.toLowerCase().contains(query) ||
        word.note.toLowerCase().contains(query) ||
        word.tag.toLowerCase().contains(query) ||
        displayCustomTag(word.tag).toLowerCase().contains(query);
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
                        '${displayDifficulty(word.difficulty)} · ${displayCustomTag(word.tag)}',
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

class _WordEntryTile extends StatelessWidget {
  const _WordEntryTile({required this.entry});

  final WordEntry entry;

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
          onTap: () => context.push('/wordbook/${entry.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageCueBadge(cue: entry.word.isNotEmpty ? entry.word[0] : '', size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        entry.definitions.isNotEmpty ? entry.definitions.first : '',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.exampleSentences.isNotEmpty ? entry.exampleSentences.first.en : '',
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
                  label: displayDifficulty(entry.difficulty),
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
