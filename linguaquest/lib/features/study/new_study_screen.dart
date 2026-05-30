import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';

class NewStudyScreen extends ConsumerWidget {
  const NewStudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final lesson = state.currentLesson;
    final dailyGoal =
        state.learningPlan?.dailyWords ?? state.user?.dailyGoal ?? 10;
    final words = lesson?.words.take(dailyGoal).toList() ?? const <Word>[];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('新学'),
        actions: [
          IconButton(
            tooltip: '词书路径',
            onPressed: () => context.push('/learn'),
            icon: const Icon(Icons.route_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            _StudyHeader(
              count: words.length,
              lesson: lesson,
              dailyGoal: dailyGoal,
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: '今日新词包',
              subtitle: '先自评，再看词卡，最后进入语境题。正式复习会单独排队。',
            ),
            const SizedBox(height: 12),
            _FlowSteps(),
            const SizedBox(height: 20),
            if (lesson == null || words.isEmpty)
              QuestCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '暂无新学词',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('当前词书已经学完，或学习计划还没有生成。可以去词书路径检查下一组内容。'),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/learn'),
                      icon: const Icon(Icons.route_outlined),
                      label: const Text('打开词书路径'),
                    ),
                  ],
                ),
              )
            else ...[
              FilledButton.icon(
                onPressed: () => context.push('/lesson/${lesson.id}'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('进入词卡学习'),
              ),
              const SizedBox(height: 16),
              for (final word in words) _WordPreviewTile(word: word),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.count,
    required this.lesson,
    required this.dailyGoal,
  });

  final int count;
  final Lesson? lesson;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final section = lesson?.section;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天先学 $count 个新词',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lesson == null
              ? '完成复习后再补新词，保持节奏比堆任务更重要。'
              : '$section · 目标 $dailyGoal 词 · 不做限时测试',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            PillLabel(label: '认识', icon: Icons.sentiment_satisfied_outlined),
            PillLabel(
              label: '模糊',
              icon: Icons.visibility_outlined,
              color: AppTheme.mango,
            ),
            PillLabel(
              label: '不认识',
              icon: Icons.help_outline,
              color: AppTheme.coral,
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', '自评', '降低无效重复'),
      ('2', '词卡', '补全释义和例句'),
      ('3', '语境题', '主动回忆'),
    ];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: QuestCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              color: i == 1 ? AppTheme.accentSurface(context) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Text(steps[i].$1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[i].$2,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    steps[i].$3,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (i != steps.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _WordPreviewTile extends StatelessWidget {
  const _WordPreviewTile({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ImageCueBadge(cue: word.imageCue, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  word.meaning,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            word.phonetic,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
