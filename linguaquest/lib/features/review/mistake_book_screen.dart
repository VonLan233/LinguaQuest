import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';

class MistakeBookScreen extends ConsumerWidget {
  const MistakeBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final lessonMistakes = state.lastResult?.mistakes ?? const [];
    final weakWords = state.weakWords;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/review'),
        title: const Text('错词本'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GradientHeroCard(
              title: lessonMistakes.isEmpty
                  ? '暂时没有课程错题'
                  : '${lessonMistakes.length} 个课程错题',
              subtitle: '测验错题和弱项自定义卡会保留在这里，方便后续复习。',
              icon: Icons.auto_fix_high_outlined,
              badge: '错题修复',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                ),
                onPressed: () => context.go('/learn'),
                icon: const Icon(Icons.route_outlined),
                label: const Text('去练一课'),
              ),
            ),
            const SizedBox(height: 20),
            if (lessonMistakes.isEmpty && weakWords.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: '错词本已清空',
                message: '测验答错，或把自定义词标记为没记住后，这里会出现复习项。',
                action: OutlinedButton.icon(
                  onPressed: () => context.go('/learn'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('开始一课'),
                ),
              )
            else ...[
              Text('课程错题', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (lessonMistakes.isEmpty)
                const Text('最近一课没有答错的题。')
              else
                for (final mistake in lessonMistakes)
                  QuestCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ImageCueBadge(cue: mistake.word.imageCue, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mistake.word.word,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(mistake.explanation),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 18),
              Text('弱项自定义词', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (weakWords.isEmpty)
                const Text('还没有弱项自定义词。')
              else
                for (final word in weakWords)
                  QuestCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.push('/custom-words/${word.id}'),
                    child: Row(
                      children: [
                        ImageCueBadge(cue: wordInitialCue(word.word), size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word.word,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('错 ${word.wrongCount} 次 · ${word.meaning}'),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
