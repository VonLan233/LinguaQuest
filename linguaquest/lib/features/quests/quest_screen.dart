import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        const SectionHeader(title: '任务中心', subtitle: '每日任务、积分和社交入口会在后续阶段继续补齐。'),
        const SizedBox(height: 12),
        const PillLabel(
          label: '今日可领 20 XP',
          icon: Icons.bolt,
          color: AppTheme.mango,
        ),
        const SizedBox(height: 16),
        const _QuestRow(
          icon: Icons.flag_outlined,
          title: '每日任务',
          body: '完成一节课程，并复习 5 个到期词。',
          value: '20 XP',
        ),
        const SizedBox(height: 10),
        const _QuestRow(
          icon: Icons.workspace_premium_outlined,
          title: '成就徽章',
          body: '连续 7 天、已学 100 词、首次满分课程等成就。',
          value: '3 个',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.leaderboard_outlined,
          title: '排行榜',
          body: '好友和未来班级的每周 XP 排名。',
          value: '模拟',
          route: '/leaderboard',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.insights_outlined,
          title: '学习分析',
          body: '正确率、词汇增长和复习完成趋势。',
          value: '预览',
          route: '/progress',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.groups_outlined,
          title: '班级模式',
          body: '通过班级码加入；教师进度看板将在服务器阶段启用。',
          value: '原型',
          route: '/class-mode',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.smart_toy_outlined,
          title: 'AI 助教',
          body: '用模拟反馈解释错因，并给出例句建议。',
          value: '模拟',
          route: '/ai-tutor',
        ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    this.route,
  });

  final IconData icon;
  final String title;
  final String body;
  final String value;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.iconBadgeSurface(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillLabel(label: value, color: AppTheme.coral),
        ],
      ),
    );

    if (route == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(route!),
        child: content,
      ),
    );
  }
}
