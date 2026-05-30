import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../data/models/lesson.dart';

class TargetWordDetailScreen extends ConsumerWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = _find(ref);
    if (word == null) {
      return const Scaffold(body: Center(child: Text('没有找到这个词')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: Text(word.word),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ImageCueBadge(cue: word.imageCue, size: 108),
                  const SizedBox(height: 16),
                  Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(word.phonetic),
                  const SizedBox(height: 12),
                  Text(
                    word.meaning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(word.definition, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: AppTheme.coral),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(word.exampleSentence),
                        const SizedBox(height: 6),
                        Text(
                          word.exampleTranslation,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: word.partOfSpeech),
                PillLabel(
                  label: displayDifficulty(word.difficulty),
                  color: AppTheme.coral,
                ),
                for (final tag in word.tags) PillLabel(label: tag),
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
