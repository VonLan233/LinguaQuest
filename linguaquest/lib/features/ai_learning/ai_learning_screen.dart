import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/compact_entry_card.dart';
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
        if (AppConstants.apiBaseUrl.isEmpty) ...[
          AppCard(
            child: Row(
              children: [
                Icon(
                  AppIcons.info,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTokens.s12),
                const Expanded(
                  child: Text(
                    'AI features use demo responses. Connect to a server for real AI.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
        ],
        SectionHeader(
          title: l10n.aiLearningTitle,
          trailing: QuestIconButton(
            tooltip: l10n.aiLearningTooltip,
            onPressed: () => context.push('/ai-tutor'),
            icon: AppIcons.chatBubble,
            color: AppTheme.cyan,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: AppPill(
            label: l10n.aiLearningPillError,
            variant: PillVariant.primary,
            icon: AppIcons.psychologyAlt,
          ),
        ),
        const SizedBox(height: AppTokens.s32),
        if (word.isNotEmpty) ...[
          _AiWordContextCard(
            word: word,
            example: example,
            translation: translation,
            l10n: l10n,
          ),
          const SizedBox(height: AppTokens.s32),
        ],
        SectionHeader(title: l10n.aiLearningToolsTitle),
        const SizedBox(height: AppTokens.s16),
        _AiToolRow(
          icon: AppIcons.questionAnswer,
          title: l10n.aiLearningToolAiQA,
          color: AppTheme.cyan,
          onTap: () => context.push(
            '/ai-chat${word.isNotEmpty ? '?word=${Uri.encodeComponent(word)}' : ''}',
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        _AiToolRow(
          icon: AppIcons.accountTree,
          title: l10n.aiLearningToolAiAnalysis,
          color: AppTokens.azure,
          onTap: () => context.push('/ai-analysis'),
        ),
        const SizedBox(height: AppTokens.s12),
        _AiToolRow(
          icon: AppIcons.autoStories,
          title: l10n.aiLearningToolCloze,
          color: AppTokens.mangoColor(context),
          onTap: () => context.push(
            '/ai-cloze${word.isNotEmpty ? '?word=${Uri.encodeComponent(word)}' : ''}',
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        _AiToolRow(
          icon: AppIcons.rateReview,
          title: l10n.aiLearningToolAiWriting,
          color: AppTokens.coralColor(context),
          onTap: () => context.push('/ai-writing-review'),
        ),
        const SizedBox(height: AppTokens.s12),
        _AiToolRow(
          icon: AppIcons.compareArrows,
          title: l10n.aiLearningToolConfusion,
          color: AppTheme.cyan,
          onTap: () => context.push('/ai-confusion'),
        ),
        const SizedBox(height: AppTokens.s12),
        _AiToolRow(
          icon: AppIcons.tipsAndUpdates,
          title: l10n.aiLearningToolSentence,
          color: AppTokens.azure,
          status: l10n.aiLearningStatusPlanning,
        ),
      ],
    );
  }
}

/// A compact AI tool entry: icon + name + status pill, no blurb.
/// When [onTap] is provided, the row is enabled and shows a success pill.
class _AiToolRow extends StatelessWidget {
  const _AiToolRow({
    required this.icon,
    required this.title,
    required this.color,
    this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: CompactEntryCard(
        icon: icon,
        title: title,
        color: color,
        enabled: enabled,
        trailing: AppPill(
          label: enabled ? l10n.aiLearningStatusAvailable : (status ?? ''),
          variant: enabled ? PillVariant.success : PillVariant.neutral,
        ),
      ),
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
          const IconCueBadge(
            icon: AppIcons.travelExplore,
            color: AppTheme.cyan,
          ),
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

