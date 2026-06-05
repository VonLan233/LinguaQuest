import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/ai_word_support_link.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import 'word_knowledge_sections.dart';

class TargetWordDetailScreen extends ConsumerWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final word = _find(state);
    if (word == null) {
      return const Scaffold(body: Center(child: Text('没有找到这个词')));
    }
    final savedWord = _savedCustomWord(state, word);
    final isSaved = savedWord != null;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: Text(word.word),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('当前计划中'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => isSaved
                      ? _removeFromCustomWords(context, ref, savedWord)
                      : _addToCustomWords(context, ref, word),
                  icon: Icon(
                    isSaved
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                  ),
                  label: Text(isSaved ? '移出生词本' : '加入生词本'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ImageCueBadge(cue: word.imageCue, size: 108),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        word.word,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      PronunciationControls(word: word.word, compact: true),
                    ],
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
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
            WordKnowledgeSections(word: word),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: word.partOfSpeech),
                PillLabel(
                  label: displayDifficulty(word.difficulty),
                  color: AppTheme.coral,
                ),
                for (final tag in word.tags)
                  PillLabel(label: displayWordTag(tag)),
              ],
            ),
            const SizedBox(height: 22),
            AiWordSupportLink(word: word.word),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCustomWords(
    BuildContext context,
    WidgetRef ref,
    Word word,
  ) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .addCustomWord(
          word: word.word,
          meaning: word.meaning,
          exampleSentence: word.exampleSentence,
          note: '${word.definition}\n${word.exampleTranslation}',
          tag: word.tags.isEmpty ? '目标词' : displayWordTag(word.tags.first),
          difficulty: word.difficulty,
        );
    if (!context.mounted) return;
    final message = succeeded
        ? '已加入生词本'
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法加入生词本';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _removeFromCustomWords(
    BuildContext context,
    WidgetRef ref,
    CustomWord word,
  ) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .deleteCustomWord(word.id);
    if (!context.mounted) return;
    final message = succeeded
        ? '已移出生词本'
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法移出生词本';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  CustomWord? _savedCustomWord(AppState state, Word word) {
    final target = word.word.trim().toLowerCase();
    for (final item in state.customWords) {
      if (item.word.trim().toLowerCase() == target) return item;
    }
    return null;
  }

  Word? _find(AppState state) {
    for (final lesson in state.formalLessons) {
      for (final word in lesson.words) {
        if (word.id == wordId) return word;
      }
    }
    return null;
  }
}
