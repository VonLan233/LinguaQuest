import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/empty_state.dart';
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
      appBar: AppBar(title: const Text('Custom words')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/custom-words/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                        onPressed: () => context.go('/custom-words/new'),
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
    await ref.read(appControllerProvider.notifier).deleteCustomWord(word.id);
    if (!mounted) return;
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(word.word.characters.first.toUpperCase()),
        ),
        title: Text(word.word),
        subtitle: Text(
          '${word.meaning} · ${word.tag} · mastery ${word.masteryLevel}/5',
        ),
        onTap: () => context.go('/custom-words/${word.id}'),
        trailing: IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
