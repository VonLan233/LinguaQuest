import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/app_controller.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/study_cat.dart';
import '../../l10n/generated/app_localizations.dart';

class AiLearningScreen extends ConsumerWidget {
  const AiLearningScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final query = GoRouterState.of(context).uri.queryParameters;
    final state = ref.watch(appControllerProvider);
    final todayWords = state.currentLesson?.words ?? [];
    final word =
        query['word']?.trim() ??
        (todayWords.isEmpty ? '' : todayWords.first.word);
    final suffix = word.isEmpty ? '' : '?word=${Uri.encodeComponent(word)}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        Text(
          l10n.aiLearningTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiCenterTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.aiCenterHint,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const StudyCat(size: 94),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppConstants.apiBaseUrl.isEmpty
                  ? Icons.info_outline
                  : Icons.wifi_outlined,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppConstants.apiBaseUrl.isEmpty
                    ? l10n.aiDemoNotice
                    : l10n.aiNetworkNotice,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          onTap: () => context.push('/ai-chat$suffix'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.aiTryThis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (word.isNotEmpty)
                Text(word, style: Theme.of(context).textTheme.headlineSmall),
              if ((query['example'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(query['example']!),
              ],
              if ((query['translation'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(query['translation']!),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.aiAskWord,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.aiLearningToolAiQA,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.aiScenarioTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        _AiToolRow(
          icon: Icons.question_answer_outlined,
          title: l10n.aiLearningToolAiQA,
          description: l10n.aiQaShort,
          route: '/ai-chat$suffix',
        ),
        _AiToolRow(
          icon: Icons.subject_rounded,
          title: l10n.aiLearningToolAiAnalysis,
          description: l10n.aiAnalysisShort,
          route: '/ai-analysis',
        ),
        _AiToolRow(
          icon: Icons.edit_note_rounded,
          title: l10n.aiLearningToolAiWriting,
          description: l10n.aiWritingShort,
          route: '/ai-writing-review',
        ),
        _AiToolRow(
          icon: Icons.compare_arrows_rounded,
          title: l10n.aiLearningToolConfusion,
          description: l10n.aiConfusionShort,
          route: '/ai-confusion',
        ),
        _AiToolRow(
          icon: Icons.auto_stories_outlined,
          title: l10n.aiLearningToolCloze,
          description: l10n.aiClozeShort,
          route: '/ai-cloze$suffix',
        ),
        _AiToolRow(
          icon: Icons.notes_rounded,
          title: l10n.aiLearningToolSentence,
          description: l10n.aiSentenceShort,
          route: '/ai-sentence',
        ),
      ],
    );
  }
}

class _AiToolRow extends StatelessWidget {
  const _AiToolRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
  final IconData icon;
  final String title, description, route;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.push(route),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
