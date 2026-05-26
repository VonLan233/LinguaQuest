import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
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
        title: const Text('Custom words'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/custom-words/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: GradientHeroCard(
                title: 'My word cards',
                subtitle:
                    'Create, search, filter, edit, and review your personal vocabulary deck.',
                icon: Icons.add_card_outlined,
                badge: '${state.customWords.length} custom cards',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search words, meanings, or tags',
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
                        label: Text(filter),
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
                      title: 'No matching words',
                      message: 'Add a custom card or adjust search filters.',
                      action: FilledButton.icon(
                        onPressed: () => context.push('/custom-words/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add word'),
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
        title: Text('Delete "${word.word}"?'),
        content: const Text(
          'This removes the custom card and its review schedule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Could not delete ${word.word}')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted ${word.word}')));
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
          ImageCueBadge(
            cue: word.word.characters.first.toUpperCase(),
            size: 58,
          ),
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
                    PillLabel(label: word.difficulty, color: AppTheme.coral),
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
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
