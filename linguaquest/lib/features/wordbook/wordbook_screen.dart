import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/section_header.dart';

class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final words = state.lessons.expand((lesson) => lesson.words).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Wordbook')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: 'Target words',
              subtitle:
                  '${words.length} words from your current learning path.',
              trailing: FilledButton.icon(
                onPressed: () => context.go('/custom-words'),
                icon: const Icon(Icons.style_outlined),
                label: const Text('Custom'),
              ),
            ),
            const SizedBox(height: 16),
            for (final word in words)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(child: Text(word.imageCue)),
                  title: Text(word.word),
                  subtitle: Text('${word.meaning} · ${word.exampleSentence}'),
                  trailing: Chip(label: Text(word.difficulty)),
                  onTap: () => context.go('/wordbook/${word.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
