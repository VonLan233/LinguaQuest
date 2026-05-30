import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        GradientHeroCard(
          title: '训练场',
          subtitle: '用已学词、到期词和弱项词做轻竞技训练，积分只奖励有效学习行为。',
          icon: Icons.sports_esports_rounded,
          badge: '本周 ${user?.xp ?? 0} 积分 · 今日可得 60',
          action: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            onPressed: () => context.push('/leaderboard'),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('查看排行榜'),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: '到期词',
                value: '${state.dueWords.length}',
                icon: Icons.today_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: '弱项词',
                value: '${state.weakWords.length}',
                icon: Icons.warning_amber_outlined,
                color: AppTheme.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: '连击目标',
                value: '10',
                icon: Icons.bolt,
                color: AppTheme.mango,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: '专项训练',
          subtitle: '先上线单人异步玩法，后续再扩展 PK 和 Boss Quiz。',
        ),
        const SizedBox(height: 12),
        _TrainingGameCard(
          icon: Icons.timer_outlined,
          title: '抢词',
          body: '60 秒内尽可能答对英文选义题，按正确数、连击和准确率给积分。',
          source: '已学词 + 到期词',
          actionLabel: '开始复习',
          onTap: () => context.push('/review'),
        ),
        _TrainingGameCard(
          icon: Icons.stairs_outlined,
          title: '一站到底',
          body: '从简单到困难连续答题，错词会进入弱项词和错词本。',
          source: '当前词书 + 弱项词',
          actionLabel: '打开学习路径',
          onTap: () => context.push('/learn'),
        ),
        _TrainingGameCard(
          icon: Icons.edit_note_outlined,
          title: '单词拼写',
          body: '看中文、听发音或看例句空格后输入英文，强化可产出能力。',
          source: '拼写弱项词',
          actionLabel: '进入生词本',
          onTap: () => context.push('/custom-words'),
        ),
        const _TrainingGameCard(
          icon: Icons.article_outlined,
          title: '文章挖词',
          body: '用今日词汇生成短文并挖空，连接背词和阅读理解。',
          source: '今日学习词 + AI 短文',
          actionLabel: '即将开放',
        ),
        const _TrainingGameCard(
          icon: Icons.hearing_outlined,
          title: '听音速答',
          body: '播放发音后选择单词或释义，反应时间影响得分。',
          source: '听力弱项词',
          actionLabel: '即将开放',
        ),
      ],
    );
  }
}

class _TrainingGameCard extends StatelessWidget {
  const _TrainingGameCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.source,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String source;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppTheme.coral),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillLabel(label: source, icon: Icons.source_outlined),
                    PillLabel(
                      label: actionLabel,
                      icon: onTap == null
                          ? Icons.lock_clock_outlined
                          : Icons.play_arrow_rounded,
                      color: onTap == null ? Colors.blueGrey : AppTheme.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
