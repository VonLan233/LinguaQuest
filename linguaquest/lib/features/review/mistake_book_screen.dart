import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';

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
            SectionHeader(
              title: lessonMistakes.isEmpty
                  ? '暂时没有课程错题'
                  : '${lessonMistakes.length} 个课程错题',
              subtitle: '测验错题和弱项自定义卡会保留在这里，方便后续复习。',
              trailing: QuestIconButton(
                tooltip: '去练一课',
                onPressed: () => context.go('/learn'),
                icon: Icons.route_outlined,
                color: AppTheme.coral,
              ),
            ),
            const SizedBox(height: 14),
            const PillLabel(
              label: '错题修复',
              icon: Icons.auto_fix_high_outlined,
              color: AppTheme.coral,
            ),
            const SizedBox(height: 20),
            if (lessonMistakes.isEmpty && weakWords.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: '错词本已清空',
                message: '测验答错，或把生词本词卡标记为没记住后，这里会出现复习项。',
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
                  _MistakeWordRow(mistake: mistake),
              const SizedBox(height: 18),
              Text('弱项生词', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (weakWords.isEmpty)
                const Text('还没有弱项生词。')
              else
                for (final word in weakWords) _WeakCustomWordRow(word: word),
            ],
          ],
        ),
      ),
    );
  }
}

class _MistakeWordRow extends StatelessWidget {
  const _MistakeWordRow({required this.mistake});

  final QuizQuestion mistake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ImageCueBadge(cue: mistake.word.imageCue, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mistake.word.word, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  mistake.explanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakCustomWordRow extends StatelessWidget {
  const _WeakCustomWordRow({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => word.source == 'target'
              ? context.push('/wordbook/${word.sourceWordId ?? word.id}')
              : context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '错 ${word.wrongCount} 次 · ${word.meaning}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
