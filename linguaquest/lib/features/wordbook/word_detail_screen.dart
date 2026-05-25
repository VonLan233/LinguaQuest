import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/utils/date_formatting.dart';
import '../../data/models/custom_word.dart';

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = _find(ref);
    if (word == null) {
      return const Scaffold(body: Center(child: Text('Word not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(word.word),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => context.go('/custom-words/${word.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.meaning,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(word.exampleSentence),
                  if (word.note.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(word.note),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(word.tag)),
                Chip(label: Text(word.difficulty)),
                Chip(label: Text('Mastery ${word.masteryLevel}/5')),
                Chip(
                  label: Text(
                    'Next ${formatRelativeDue(word.nextReviewAt, DateTime.now())}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .reviewWord(word.id, true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark remembered'),
            ),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .reviewWord(word.id, false),
              icon: const Icon(Icons.replay),
              label: const Text('Practice again soon'),
            ),
          ],
        ),
      ),
    );
  }

  CustomWord? _find(WidgetRef ref) {
    for (final word in ref.watch(appControllerProvider).customWords) {
      if (word.id == wordId) return word;
    }
    return null;
  }
}
