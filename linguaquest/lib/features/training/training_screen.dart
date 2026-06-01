import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
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
        SectionHeader(
          title: '训练场',
          subtitle: '限时测试、专项训练和排行榜放在这里；正式新学与复习保持独立。',
          trailing: QuestIconButton(
            tooltip: '排行榜',
            onPressed: () => context.push('/leaderboard'),
            icon: Icons.leaderboard_outlined,
            color: AppTheme.coral,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: '本周 ${user?.xp ?? 0} XP',
              icon: Icons.bolt,
              color: AppTheme.mango,
            ),
            const PillLabel(
              label: '今日可得 60 XP',
              icon: Icons.add_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _TrainingReadinessLine(
          dueWords: state.dueWords.length,
          weakWords: state.weakWords.length,
          comboTarget: 10,
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: '限时测试',
          subtitle: '校园词包和抢词挑战归入训练场，不再占用新学入口。',
        ),
        const SizedBox(height: 12),
        _TrainingGameList(
          games: [
            _TrainingGameData(
              icon: Icons.hearing_outlined,
              title: '听音速答',
              body: '播放发音后选择单词或释义，反应速度和正确率共同影响积分。',
              source: '校园词包 · 听音题',
              actionLabel: '开始听音',
              onTap: () => context.push('/timed-test/lesson-campus-1'),
            ),
            _TrainingGameData(
              icon: Icons.timer_outlined,
              title: '抢词',
              body: '60 秒内尽可能答对英文选义题，按正确数、连击和准确率给积分。',
              source: '已学词 + 到期词',
              actionLabel: '开始抢词',
              onTap: () => context.push('/timed-test/lesson-speed-1'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: '专项训练', subtitle: '围绕拼写、听音、搭配和短文挖词补弱项。'),
        const SizedBox(height: 12),
        _TrainingGameList(
          games: [
            _TrainingGameData(
              icon: Icons.stairs_outlined,
              title: '一站到底',
              body: '从简单到困难连续答题，错词会进入弱项词和错词本。',
              source: '当前词书 + 弱项词',
              actionLabel: '开始闯关',
              onTap: () => context.push('/timed-test/lesson-gauntlet-1'),
            ),
            _TrainingGameData(
              icon: Icons.edit_note_outlined,
              title: '单词拼写',
              body: '看中文、听发音或看例句空格后输入英文，强化可产出能力。',
              source: '拼写弱项词',
              actionLabel: '开始拼写',
              onTap: () => context.push('/timed-test/lesson-spelling-1'),
            ),
            _TrainingGameData(
              icon: Icons.article_outlined,
              title: '文章挖词',
              body: '用今日词汇生成短文并挖空，连接背词和阅读理解。',
              source: '今日学习词 + AI 短文',
              actionLabel: '开始挖词',
              onTap: () => context.push('/timed-test/lesson-cloze-1'),
            ),
            _TrainingGameData(
              icon: Icons.hearing_outlined,
              title: '听音复练',
              body: '复练听音选词和听音选义，错误记录会进入训练统计。',
              source: '听力弱项词',
              actionLabel: '开始复练',
              onTap: () => context.push('/timed-test/lesson-campus-1'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrainingReadinessLine extends StatelessWidget {
  const _TrainingReadinessLine({
    required this.dueWords,
    required this.weakWords,
    required this.comboTarget,
  });

  final int dueWords;
  final int weakWords;
  final int comboTarget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrainingSignal(
            label: '到期词',
            value: '$dueWords',
            icon: Icons.today_outlined,
            color: AppTheme.teal,
          ),
        ),
        const _TrainingSignalDivider(),
        Expanded(
          child: _TrainingSignal(
            label: '弱项词',
            value: '$weakWords',
            icon: Icons.warning_amber_outlined,
            color: AppTheme.coral,
          ),
        ),
        const _TrainingSignalDivider(),
        Expanded(
          child: _TrainingSignal(
            label: '连击目标',
            value: '$comboTarget',
            icon: Icons.bolt,
            color: AppTheme.mango,
          ),
        ),
      ],
    );
  }
}

class _TrainingSignal extends StatelessWidget {
  const _TrainingSignal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainingSignalDivider extends StatelessWidget {
  const _TrainingSignalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: VerticalDivider(
        width: 16,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _TrainingGameList extends StatelessWidget {
  const _TrainingGameList({required this.games});

  final List<_TrainingGameData> games;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < games.length; index++) ...[
          _TrainingGameRow(game: games[index]),
          if (index != games.length - 1)
            Divider(
              height: 10,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _TrainingGameRow extends StatelessWidget {
  const _TrainingGameRow({required this.game});

  final _TrainingGameData game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(icon: game.icon, color: AppTheme.coral),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  game.body,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillLabel(label: game.source, icon: Icons.source_outlined),
                    PillLabel(
                      label: game.actionLabel,
                      icon: game.onTap == null
                          ? Icons.lock_clock_outlined
                          : Icons.play_arrow_rounded,
                      color: game.onTap == null
                          ? Colors.blueGrey
                          : AppTheme.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (game.onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: game.onTap,
        child: content,
      ),
    );
  }
}

class _TrainingGameData {
  const _TrainingGameData({
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
}
