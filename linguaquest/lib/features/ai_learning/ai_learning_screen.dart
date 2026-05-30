import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class AiLearningScreen extends StatelessWidget {
  const AiLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: 'AI学习',
          subtitle: '解释语法、辨析词义、生成语境；正式学习记录仍由答题结果更新。',
          trailing: IconButton.filledTonal(
            tooltip: '知识问答',
            onPressed: () => context.push('/ai-tutor'),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(label: 'Mock first', icon: Icons.science_outlined),
            PillLabel(
              label: 'No client API key',
              icon: Icons.lock_outline,
              color: AppTheme.cyan,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: '工具列表',
          subtitle: '首版优先落地长难句分析和知识问答，作文批改后置。',
        ),
        const SizedBox(height: 12),
        _AiToolCard(
          icon: Icons.rate_review_outlined,
          title: 'AI 作文批改',
          body: '选择考试类型、输入题目和正文，输出总评分、分项评分和逐段修改建议。',
          status: 'P2',
        ),
        _AiToolCard(
          icon: Icons.account_tree_outlined,
          title: 'AI 长难句分析',
          body: '提取主干、划分从句、解释修饰成分和关键词，并给出自然中文翻译。',
          status: 'Mock',
          onTap: () => context.push('/ai-tutor'),
        ),
        _AiToolCard(
          icon: Icons.auto_stories_outlined,
          title: '今日单词情景填空',
          body: '基于今日新词、错词或本周弱词生成短文，挖空 5 到 10 个目标词。',
          status: 'P1',
        ),
        _AiToolCard(
          icon: Icons.question_answer_outlined,
          title: 'AI 知识问答',
          body: '结合当前单词、例句和学习目标回答词义、语法和表达自然度问题。',
          status: 'Ready',
          onTap: () => context.push('/ai-tutor'),
        ),
        const _AiToolCard(
          icon: Icons.compare_arrows_outlined,
          title: '易混词辨析',
          body: '根据错题混淆记录，解释 affect/effect 这类近义或易混词的使用场景。',
          status: 'P1',
        ),
        const _AiToolCard(
          icon: Icons.tips_and_updates_outlined,
          title: '例句生成与改写',
          body: '按考试目标生成更自然的例句，并支持一键加入笔记或生词本。',
          status: 'P1',
        ),
      ],
    );
  }
}

class _AiToolCard extends StatelessWidget {
  const _AiToolCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String status;
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
              color: AppTheme.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppTheme.deepTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillLabel(
            label: status,
            color: onTap == null ? Colors.blueGrey : AppTheme.teal,
          ),
        ],
      ),
    );
  }
}
