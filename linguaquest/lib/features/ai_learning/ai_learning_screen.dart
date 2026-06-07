import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';

class AiLearningScreen extends StatelessWidget {
  const AiLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final word = query['word']?.trim() ?? '';
    final example = query['example']?.trim() ?? '';
    final translation = query['translation']?.trim() ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: 'AI 学习',
          subtitle: '解释语法、辨析词义、生成语境；正式学习记录仍由答题结果更新。',
          trailing: QuestIconButton(
            tooltip: '知识问答',
            onPressed: () => context.push('/ai-tutor'),
            icon: Icons.chat_bubble_outline,
            color: AppTheme.cyan,
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(label: '错因讲解', icon: Icons.psychology_alt_outlined),
            PillLabel(
              label: '无需客户端密钥',
              icon: Icons.lock_outline,
              color: AppTheme.cyan,
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (word.isNotEmpty) ...[
          _AiWordContextCard(
            word: word,
            example: example,
            translation: translation,
          ),
          const SizedBox(height: 22),
        ],
        const SectionHeader(
          title: '工具列表',
          subtitle: '首版优先落地长难句分析和知识问答，作文批改后置。',
        ),
        const SizedBox(height: 12),
        _AiToolList(
          tools: [
            _AiToolData(
              icon: Icons.question_answer_outlined,
              title: 'AI 知识问答',
              body: '结合当前单词、例句和学习目标回答词义、语法和表达自然度问题。',
              status: '可用',
              onTap: () => context.push('/ai-tutor'),
            ),
            _AiToolData(
              icon: Icons.account_tree_outlined,
              title: 'AI 长难句分析',
              body: '提取主干、划分从句、解释修饰成分和关键词，并给出自然中文翻译。',
              status: '可试用',
              onTap: () => context.push('/ai-tutor'),
            ),
            const _AiToolData(
              icon: Icons.rate_review_outlined,
              title: 'AI 作文批改',
              body: '选择考试类型、输入题目和正文，输出总评分、分项评分和逐段修改建议。',
              status: '待开放',
            ),
            const _AiToolData(
              icon: Icons.auto_stories_outlined,
              title: '今日单词情景填空',
              body: '基于今日新词、错词或本周弱词生成短文，挖空 5 到 10 个目标词。',
              status: '规划中',
            ),
            const _AiToolData(
              icon: Icons.compare_arrows_outlined,
              title: '易混词辨析',
              body: '根据错题混淆记录，解释 affect/effect 这类近义或易混词的使用场景。',
              status: '规划中',
            ),
            const _AiToolData(
              icon: Icons.tips_and_updates_outlined,
              title: '例句生成与改写',
              body: '按考试目标生成更自然的例句，并支持一键加入笔记或生词本。',
              status: '规划中',
            ),
          ],
        ),
      ],
    );
  }
}

class _AiWordContextCard extends StatelessWidget {
  const _AiWordContextCard({
    required this.word,
    required this.example,
    required this.translation,
  });

  final String word;
  final String example;
  final String translation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.selectedSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconCueBadge(icon: Icons.travel_explore, color: AppTheme.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前词：$word', style: theme.textTheme.titleMedium),
                if (example.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(example),
                ],
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    translation,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiToolList extends StatelessWidget {
  const _AiToolList({required this.tools});

  final List<_AiToolData> tools;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < tools.length; index++) ...[
          _AiToolLink(tool: tools[index]),
          if (index != tools.length - 1)
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

class _AiToolLink extends StatelessWidget {
  const _AiToolLink({required this.tool});

  final _AiToolData tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(icon: tool.icon, color: AppTheme.deepTeal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tool.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  tool.body,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillLabel(
            label: tool.status,
            color: tool.onTap == null ? Colors.blueGrey : AppTheme.teal,
          ),
        ],
      ),
    );

    if (tool.onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: tool.onTap,
        child: content,
      ),
    );
  }
}

class _AiToolData {
  const _AiToolData({
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
}
