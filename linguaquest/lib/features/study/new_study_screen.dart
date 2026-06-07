import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lesson.dart';

class NewStudyScreen extends ConsumerWidget {
  const NewStudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final lesson = state.currentLesson;
    final dailyGoal = state.dailyNewTarget;
    final words = lesson?.words.take(dailyGoal).toList() ?? const <Word>[];
    final canStart =
        lesson != null && words.isNotEmpty && !state.isStudyPlanPaused;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('新学'),
        actions: [
          QuestIconButton(
            tooltip: '词书路径',
            onPressed: () => context.push('/learn'),
            icon: Icons.route_outlined,
          ),
          const SizedBox(width: 12),
        ],
      ),
      bottomNavigationBar: canStart
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/lesson/${lesson.id}'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('进入词卡学习'),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, canStart ? 100 : 28),
          children: [
            _StudyHeader(
              count: words.length,
              lesson: lesson,
              dailyGoal: dailyGoal,
              isPaused: state.isStudyPlanPaused,
            ),
            const SizedBox(height: 20),
            Text(
              '今日新词包',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '先自评，再看词卡，最后进入语境题。正式复习会单独排队。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _FlowSteps(),
            const SizedBox(height: 20),
            if (lesson == null || words.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '暂无新学词',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isStudyPlanPaused
                          ? '学习计划已暂停。恢复计划后，系统会继续安排今日新词。'
                          : '当前词书已经学完，或学习计划还没有生成。可以去词书路径检查下一组内容。',
                    ),
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
    required this.isPaused,
  });

  final int count;
  final Lesson? lesson;
  final int dailyGoal;
  final bool isPaused;

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
              : isPaused
              ? '学习计划已暂停，恢复后继续从 $section 开始。'
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: i == 1
                        ? colorScheme.secondaryContainer
                        : colorScheme.primary,
                    foregroundColor: i == 1
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimary,
                    child: Text(steps[i].$1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    steps[i].$3,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 17),
                  child: Divider(
                    color: colorScheme.outlineVariant,
                    thickness: 2,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WordPreviewTile extends StatelessWidget {
  const _WordPreviewTile({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              ImageCueBadge(cue: word.imageCue, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.word, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      word.meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 82),
                child: Text(
                  word.phonetic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
