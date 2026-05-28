import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class WordbookScreen extends ConsumerWidget {
  const WordbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final words = state.lessons.expand((lesson) => lesson.words).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('Wordbook'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GradientHeroCard(
              title: 'Visual Wordbook',
              subtitle:
                  'Image-first cards connect pronunciation, meaning, examples, tags, and review signals.',
              icon: Icons.style_outlined,
              badge: '${words.length} target words',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                ),
                onPressed: () => context.push('/custom-words'),
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('My custom cards'),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Target Words',
              subtitle:
                  '${words.length} words · ${(state.learningPathProgress * 100).round()}% path progress',
            ),
            const SizedBox(height: 16),
            for (final word in words)
              QuestCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                onTap: () => context.push('/wordbook/${word.id}'),
                child: Row(
                  children: [
                    ImageCueBadge(cue: word.imageCue, size: 62),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.word,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(word.meaning),
                          const SizedBox(height: 3),
                          Text(
                            '${word.phonetic} · ${word.partOfSpeech}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            word.exampleSentence,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PillLabel(
                          label: word.difficulty,
                          color: word.difficulty == 'Hard'
                              ? Theme.of(context).colorScheme.error
                              : AppTheme.coral,
                        ),
                        if (word.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          PillLabel(label: word.tags.first),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
