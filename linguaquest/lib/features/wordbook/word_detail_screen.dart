import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/ai_word_support_link.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/quest_panel.dart';
import '../../data/models/custom_word.dart';
import '../../l10n/generated/app_localizations.dart';
import 'word_knowledge_sections.dart';

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final word = _find(ref);
    if (word == null) {
      return Scaffold(body: Center(child: Text(l10n.wordDetailNotFound)));
    }
    final state = ref.watch(appControllerProvider);
    final canReview = word.isDue(DateTime.now()) && !state.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/custom-words'),
        title: Text(word.word),
        actions: [
          QuestIconButton(
            tooltip: l10n.commonEdit,
            onPressed: () => context.push('/custom-words/${word.id}/edit'),
            icon: Icons.edit_outlined,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            QuestPanel(
              padding: const EdgeInsets.all(AppTokens.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ImageCueBadge(cue: wordInitialCue(word.word), size: 104),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        word.word,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      PronunciationControls(word: word.word, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.meaning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '“${word.exampleSentence}”',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (word.note.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(word.note, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: displayCustomTag(word.tag)),
                PillLabel(
                  label: displayDifficulty(word.difficulty),
                  color: AppTheme.coral,
                ),
                PillLabel(
                  label: l10n.wordDetailMasteryLabel('${word.masteryLevel}'),
                  icon: Icons.psychology_outlined,
                ),
                PillLabel(
                  label: l10n.wordDetailNextReview(
                    formatRelativeDue(word.nextReviewAt, DateTime.now()),
                  ),
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
            WordKnowledgeSections.custom(word: word),
            const SizedBox(height: 20),
            AiWordSupportLink(word: word.word),
            const SizedBox(height: 20),
            QuestPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.wordDetailReviewStats,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatLine(
                          label: l10n.wordDetailStatRemembered,
                          value: '${word.correctCount}',
                        ),
                      ),
                      Expanded(
                        child: _StatLine(
                          label: l10n.wordDetailStatForgot,
                          value: '${word.wrongCount}',
                        ),
                      ),
                      Expanded(
                        child: _StatLine(
                          label: l10n.wordDetailStatMastery,
                          value: '${word.masteryLevel}/5',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canReview
                  ? () => _review(context, ref, word.id, isCorrect: true)
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.wordDetailMarkRemembered),
            ),
            OutlinedButton.icon(
              onPressed: canReview
                  ? () => _review(context, ref, word.id, isCorrect: false)
                  : null,
              icon: const Icon(Icons.replay),
              label: Text(l10n.wordDetailScheduleSoon),
            ),
          ],
        ),
      ),
    );
  }

  CustomWord? _find(WidgetRef ref) {
    for (final word in ref.watch(appControllerProvider).customWords) {
      if (word.id == wordId) return word;
    }
    return null;
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    String id, {
    required bool isCorrect,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .reviewWord(id, isCorrect);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = succeeded
        ? isCorrect
              ? l10n.wordDetailMarkedRemembered
              : l10n.wordDetailScheduledSoon
        : ref.read(appControllerProvider).errorMessage ??
              l10n.wordDetailUpdateFailed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
