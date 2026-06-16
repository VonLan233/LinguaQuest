import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
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
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        88,
      ),
      children: [
        SectionHeader(
          title: l10n.aiLearningTitle,
          trailing: QuestIconButton(
            tooltip: l10n.aiLearningTooltip,
            onPressed: () => context.push('/ai-tutor'),
            icon: Icons.chat_bubble_outline,
            color: AppTheme.cyan,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: AppPill(
            label: l10n.aiLearningPillError,
            variant: PillVariant.streak,
            icon: Icons.psychology_alt_outlined,
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        if (word.isNotEmpty) ...[
          _AiWordContextCard(
            word: word,
            example: example,
            translation: translation,
            l10n: l10n,
          ),
          const SizedBox(height: AppTokens.s24),
        ],
        SectionHeader(title: l10n.aiLearningToolsTitle),
        const SizedBox(height: AppTokens.s12),
        _AiToolList(
          children: [
            _AiToolLink(
              icon: Icons.question_answer_outlined,
              title: l10n.aiLearningToolAiQA,
              subtitle: l10n.aiLearningToolAiQADesc,
              color: AppTheme.cyan,
              status: l10n.aiLearningStatusSoon,
              onTap: () => context.push('/ai-tutor'),
            ),
            _AiToolLink(
              icon: Icons.account_tree_outlined,
              title: l10n.aiLearningToolAiAnalysis,
              subtitle: l10n.aiLearningToolAiAnalysisDesc,
              color: AppTokens.azure,
              status: l10n.aiLearningStatusSoon,
              onTap: () => context.push('/ai-tutor'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s8,
            vertical: AppTokens.s4,
          ),
          child: Column(
            children: [
              _AiToolRow(
                icon: Icons.rate_review_outlined,
                title: l10n.aiLearningToolAiWriting,
                subtitle: l10n.aiLearningToolAiWritingDesc,
                color: AppTokens.coralColor(context),
                status: l10n.aiLearningStatusLater,
              ),
              _AiToolRow(
                icon: Icons.auto_stories_outlined,
                title: l10n.aiLearningToolCloze,
                subtitle: l10n.aiLearningToolClozeDesc,
                color: AppTokens.mangoColor(context),
                status: l10n.aiLearningStatusPlanning,
              ),
              _AiToolRow(
                icon: Icons.compare_arrows_outlined,
                title: l10n.aiLearningToolConfusion,
                subtitle: l10n.aiLearningToolConfusionDesc,
                color: AppTheme.cyan,
                status: l10n.aiLearningStatusPlanning,
              ),
              _AiToolRow(
                icon: Icons.tips_and_updates_outlined,
                title: l10n.aiLearningToolSentence,
                subtitle: l10n.aiLearningToolSentenceDesc,
                color: AppTokens.azure,
                status: l10n.aiLearningStatusPlanning,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiToolList extends StatelessWidget {
  const _AiToolList({required this.children});

  final List<_AiToolLink> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index < children.length - 1) const SizedBox(width: AppTokens.s12),
        ],
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
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconCueBadge(icon: Icons.travel_explore, color: AppTheme.cyan),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.aiLearningCurrentWord}: $word',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (example.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(example),
                ],
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    translation,
                    style: theme.textTheme.bodyMedium?.copyWith(
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

class _AiToolLink extends StatelessWidget {
  const _AiToolLink({
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
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                AppPill(
                  label: status,
                  variant: onTap == null
                      ? PillVariant.neutral
                      : PillVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiToolRow extends StatelessWidget {
  const _AiToolRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(icon: icon, color: color),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          AppPill(label: status, variant: PillVariant.neutral),
        ],
      ),
    );
  }
}
