import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      const _OnboardingStepData(
        cue: '🖼',
        icon: Icons.image_search_outlined,
        title: '图像词卡',
        body: '单词、释义、例句、掌握度和视觉线索在同一条学习流里串起来。',
      ),
      const _OnboardingStepData(
        cue: '🛤',
        icon: Icons.route_outlined,
        title: '清晰路径',
        body: '短课节负责安排下一步学习，让每天打开应用后知道先做什么。',
      ),
      const _OnboardingStepData(
        cue: '🔁',
        icon: Icons.replay_outlined,
        title: '准时复习',
        body: '弱项词更快回到队列，已掌握的词会拉长复习间隔。',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                const BrandMark(size: 62),
                const SizedBox(width: 14),
                const Expanded(
                  child: SectionHeader(
                    title: 'LinguaQuest',
                    subtitle: '短课节、视觉记忆卡和智能复习，帮你稳定积累英语词汇。',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: '词境星球', icon: Icons.auto_stories_outlined),
                PillLabel(label: 'XP', icon: Icons.bolt, color: AppTheme.mango),
                PillLabel(
                  label: '连续打卡',
                  icon: Icons.local_fire_department,
                  color: AppTheme.coral,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('像游戏闯关一样完成每日学习', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _OnboardingStepList(steps: steps),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('注册账号'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepList extends StatelessWidget {
  const _OnboardingStepList({required this.steps});

  final List<_OnboardingStepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _OnboardingStepRow(step: steps[index]),
          if (index != steps.length - 1)
            Divider(
              height: 18,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _OnboardingStepRow extends StatelessWidget {
  const _OnboardingStepRow({required this.step});

  final _OnboardingStepData step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ImageCueBadge(cue: step.cue, size: 62),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    step.icon,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(step.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.cue,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String cue;
  final IconData icon;
  final String title;
  final String body;
}
