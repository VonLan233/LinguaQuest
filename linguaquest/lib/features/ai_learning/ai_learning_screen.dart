import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class AiLearningScreen extends StatelessWidget {
  const AiLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = GoRouterState.of(context).uri.queryParameters;
    final word = query['word']?.trim() ?? '';
    final example = query['example']?.trim() ?? '';
    final translation = query['translation']?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: l10n.aiLearningTitle,
          subtitle: l10n.aiLearningDesc,
          trailing: QuestIconButton(
            tooltip: l10n.aiLearningTooltip,
            onPressed: () => context.push('/ai-tutor'),
            icon: Icons.chat_bubble_outline,
            color: AppTheme.cyan,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: l10n.aiLearningPillError,
              icon: Icons.psychology_alt_outlined,
            ),
            PillLabel(
              label: l10n.aiLearningPillNoKey,
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
            l10n: l10n,
          ),
          const SizedBox(height: 22),
        ],
        SectionHeader(
          title: l10n.aiLearningToolsTitle,
          subtitle: l10n.aiLearningToolsSubtitle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AiToolCard(
                icon: Icons.question_answer_outlined,
                title: l10n.aiLearningToolAiQA,
                subtitle: l10n.aiLearningToolAiQADesc,
                color: AppTheme.cyan,
                status: l10n.aiLearningStatusSoon,
                onTap: () => context.push('/ai-tutor'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AiToolCard(
                icon: Icons.account_tree_outlined,
                title: l10n.aiLearningToolAiAnalysis,
                subtitle: l10n.aiLearningToolAiAnalysisDesc,
                color: AppTheme.teal,
                status: l10n.aiLearningStatusSoon,
                onTap: () => context.push('/ai-tutor'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AiToolCard(
          icon: Icons.rate_review_outlined,
          title: l10n.aiLearningToolAiWriting,
          subtitle: l10n.aiLearningToolAiWritingDesc,
          color: AppTheme.coral,
          status: l10n.aiLearningStatusLater,
        ),
        const SizedBox(height: 12),
        _AiToolCard(
          icon: Icons.auto_stories_outlined,
          title: l10n.aiLearningToolCloze,
          subtitle: l10n.aiLearningToolClozeDesc,
          color: AppTheme.mango,
          status: l10n.aiLearningStatusPlanning,
        ),
        const SizedBox(height: 12),
        _AiToolCard(
          icon: Icons.compare_arrows_outlined,
          title: l10n.aiLearningToolConfusion,
          subtitle: l10n.aiLearningToolConfusionDesc,
          color: AppTheme.cyan,
          status: l10n.aiLearningStatusPlanning,
        ),
        const SizedBox(height: 12),
        _AiToolCard(
          icon: Icons.tips_and_updates_outlined,
          title: l10n.aiLearningToolSentence,
          subtitle: l10n.aiLearningToolSentenceDesc,
          color: AppTheme.teal,
          status: l10n.aiLearningStatusPlanning,
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
    required this.l10n,
  });

  final String word;
  final String example;
  final String translation;
  final AppLocalizations l10n;

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
          const IconCueBadge(
            icon: Icons.travel_explore,
            color: AppTheme.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.aiLearningCurrentWord}: $word',
                  style: theme.textTheme.titleMedium,
                ),
                if (example.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(example),
                ],
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    translation,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _AiToolCard extends StatelessWidget {
  const _AiToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 32),
                    const Spacer(),
                    PillLabel(
                      label: status,
                      color: onTap == null ? Colors.blueGrey : AppTheme.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
