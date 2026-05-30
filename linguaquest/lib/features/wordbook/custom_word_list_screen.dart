import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class CustomWordListScreen extends ConsumerStatefulWidget {
  const CustomWordListScreen({super.key});

  @override
  ConsumerState<CustomWordListScreen> createState() =>
      _CustomWordListScreenState();
}

class _CustomWordListScreenState extends ConsumerState<CustomWordListScreen> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final words = _filtered(state.customWords);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: const Text('自定义词卡'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/custom-words/new'),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: SectionHeader(
                title: '我的词卡',
                subtitle: '创建、搜索、筛选、编辑并复习你的个人词库。',
                trailing: PillLabel(
                  label: '${state.customWords.length} 张',
                  icon: Icons.add_card_outlined,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '搜索单词、释义或标签',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final filter in const [
                    'All',
                    'Easy',
                    'Medium',
                    'Hard',
                    'Weak',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(displayDifficultyFilter(filter)),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: words.isEmpty
                  ? EmptyState(
                      icon: Icons.style_outlined,
                      title: '没有匹配的词卡',
                      message: '可以添加一张自定义词卡，或调整搜索条件。',
                      action: FilledButton.icon(
                        onPressed: () => context.push('/custom-words/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('添加单词'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: words.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CustomWordTile(
                        word: words[index],
                        onDelete: () => _confirmDelete(words[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<CustomWord> _filtered(List<CustomWord> words) {
    final query = _query.trim().toLowerCase();
    return words.where((word) {
      final matchesQuery =
          query.isEmpty ||
          word.word.toLowerCase().contains(query) ||
          word.meaning.toLowerCase().contains(query) ||
          word.tag.toLowerCase().contains(query);
      final matchesFilter =
          _filter == 'All' ||
          word.difficulty == _filter ||
          (_filter == 'Weak' && word.isWeak);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _confirmDelete(CustomWord word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除“${word.word}”？'),
        content: const Text('这会同时删除自定义词卡和它的复习计划。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .deleteCustomWord(word.id);
    if (!mounted) return;
    if (!succeeded) {
      final message = ref.read(appControllerProvider).errorMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message ?? '暂时无法删除 ${word.word}')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除 ${word.word}')));
  }
}

class _CustomWordTile extends StatelessWidget {
  const _CustomWordTile({required this.word, required this.onDelete});

  final CustomWord word;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mastery = word.masteryLevel / 5;
    return QuestCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/custom-words/${word.id}'),
      child: Row(
        children: [
          ImageCueBadge(cue: wordInitialCue(word.word), size: 58),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    PillLabel(
                      label: displayDifficulty(word.difficulty),
                      color: AppTheme.coral,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${word.meaning} · ${word.tag}'),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: mastery,
                    minHeight: 8,
                    backgroundColor: AppTheme.progressTrack(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
