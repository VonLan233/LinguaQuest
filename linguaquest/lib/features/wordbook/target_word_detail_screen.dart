import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../data/models/lesson.dart';

class TargetWordDetailScreen extends ConsumerWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = _find(ref);
    if (word == null) {
      return const Scaffold(body: Center(child: Text('Word not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(word.word)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text(word.imageCue, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 16),
            Text(
              word.word,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(word.phonetic),
            const SizedBox(height: 12),
            Text(word.meaning, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(word.definition),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.format_quote),
              title: Text(word.exampleSentence),
              subtitle: Text(word.exampleTranslation),
            ),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(word.partOfSpeech)),
                Chip(label: Text(word.difficulty)),
                for (final tag in word.tags) Chip(label: Text(tag)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Word? _find(WidgetRef ref) {
    for (final lesson in ref.watch(appControllerProvider).lessons) {
      for (final word in lesson.words) {
        if (word.id == wordId) return word;
      }
    }
    return null;
  }
}
