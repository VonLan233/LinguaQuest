import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

class LessonPreviewScreen extends ConsumerStatefulWidget {
  const LessonPreviewScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<LessonPreviewScreen> createState() =>
      _LessonPreviewScreenState();
}

class _LessonPreviewScreenState extends ConsumerState<LessonPreviewScreen> {
  final Map<String, String> _confidenceByWordId = {};
  int _wordIndex = 0;

  @override
  void didUpdateWidget(LessonPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId == widget.lessonId) return;
    _confidenceByWordId.clear();
    _wordIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lesson = _findLesson(ref);
    if (lesson == null) {
      return Scaffold(body: Center(child: Text(l10n.lessonPreviewNoLesson)));
    }

    final words = lesson.words;
    final currentIndex = words.isEmpty
        ? 0
        : _wordIndex.clamp(0, words.length - 1).toInt();
    final word = words.isEmpty ? null : words[currentIndex];
    final selectedConfidence = word == null
        ? null
        : _confidenceByWordId[word.id];
    final progress = words.isEmpty ? 0.0 : (currentIndex + 1) / words.length;
    final isLastWord = currentIndex >= words.length - 1;

    return PopScope(
      canPop: !_hasStarted,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleBack(context)),
          title: Text(l10n.lessonPreviewTitle),
        ),
        bottomNavigationBar: word == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: l10n.lessonPreviewPrevious,
                            onPressed: _wordIndex == 0
                                ? null
                                : () => setState(() => _wordIndex--),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppPrimaryButton(
                            label: isLastWord
                                ? l10n.lessonPreviewEnterContext
                                : l10n.lessonPreviewNextCard,
                            icon: isLastWord
                                ? AppIcons.playArrow
                                : AppIcons.arrowForward,
                            onPressed: selectedConfidence == null
                                ? null
                                : () {
                                    if (isLastWord) {
                                      context.push(
                                        '/lesson/${widget.lessonId}/quiz',
                                      );
                                      return;
                                    }
                                    setState(() => _wordIndex++);
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            children: [
              SectionHeader(
                title: l10n.lessonPreviewBuildUnderstanding,
                subtitle: l10n.lessonPreviewProgressMeta(
                  lesson.section,
                  '${lesson.estimatedMinutes}',
                  '${words.isEmpty ? 0 : currentIndex + 1}',
                  '${words.length}',
                ),
              ),
              const SizedBox(height: 12),
              AppProgressBar(value: progress, height: 10),
              const SizedBox(height: 18),
              if (word == null)
                MascotEmptyState(
                  title: l10n.lessonPreviewNoCards,
                  message: l10n.lessonPreviewNoCardsBody,
                )
              else ...[
                _WordStudyCard(word: word),
                const SizedBox(height: 14),
                _ConfidenceSelector(
                  selected: selectedConfidence,
                  onSelected: (value) {
                    setState(() => _confidenceByWordId[word.id] = value);
                  },
                ),
                const SizedBox(height: 14),
                _ContextSection(word: word),
                const SizedBox(height: 24),
                SectionHeader(
                  title: l10n.lessonPreviewLessonCards,
                  subtitle: l10n.lessonPreviewCardMeta(
                    '${lesson.xpReward}',
                    '${lesson.questions.length}',
                  ),
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < words.length; index++)
                  _MiniWordRow(
                    word: words[index],
                    isCurrent: index == currentIndex,
                    isChecked: _confidenceByWordId.containsKey(words[index].id),
                    onTap: () => setState(() => _wordIndex = index),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasStarted => _wordIndex > 0 || _confidenceByWordId.isNotEmpty;

  Future<void> _handleBack(BuildContext activeContext) async {
    if (_hasStarted) {
      final dialogL10n = AppLocalizations.of(activeContext);
      final confirmed = await showDialog<bool>(
        context: activeContext,
        builder: (context) => AlertDialog(
          title: Text(dialogL10n.lessonPreviewLeaveCardTitle),
          content: Text(dialogL10n.lessonPreviewLeaveCardContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dialogL10n.mixedContinueStudy),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(AppIcons.exitToApp),
              label: Text(dialogL10n.lessonPreviewLeave),
            ),
          ],
        ),
      );
      if (confirmed != true || !activeContext.mounted) return;
    }
    if (!activeContext.mounted) return;
    if (activeContext.canPop()) {
      activeContext.pop();
      return;
    }
    activeContext.go('/study/new');
  }

  Lesson? _findLesson(WidgetRef ref) {
    for (final lesson in ref.watch(appControllerProvider).formalLessons) {
      if (lesson.id == widget.lessonId) return lesson;
    }
    return null;
  }
}

class _WordStudyCard extends StatelessWidget {
  const _WordStudyCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageCueBadge(cue: word.imageCue, size: 72),
              const SizedBox(width: AppTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Text(word.word, style: theme.textTheme.headlineSmall),
                        PronunciationControls(word: word.word, compact: true),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      word.phonetic,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppPill(label: word.partOfSpeech),
                        AppPill(
                          label: displayDifficulty(word.difficulty),
                          variant: PillVariant.streak,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s20),
          Text(
            word.primaryDefinitionFor(
              Localizations.localeOf(context).languageCode,
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(word.definition),
        ],
      ),
    );
  }
}

class _ConfidenceSelector extends StatelessWidget {
  const _ConfidenceSelector({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        l10n.studyRecallKnown,
        AppIcons.sentimentSatisfiedAlt,
        AppTokens.azure,
      ),
      (l10n.studyRecallFuzzy, AppIcons.visibility, AppTokens.mango),
      (l10n.studyRecallUnknown, AppIcons.help, AppTokens.coral),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lessonPreviewAssessFirst,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: _ConfidenceOption(
                  label: items[index].$1,
                  icon: items[index].$2,
                  color: items[index].$3,
                  selected: selected == items[index].$1,
                  onTap: () => onSelected(items[index].$1),
                ),
              ),
              if (index != items.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _ConfidenceOption extends StatelessWidget {
  const _ConfidenceOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: selected ? AppTokens.primarySoft : null,
        side: BorderSide(
          color: selected ? color : AppTokens.hairline,
          width: selected ? 2 : 1,
        ),
      ),
      icon: Icon(icon, color: selected ? color : null),
      label: FittedBox(child: Text(label)),
    );
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.formatQuote,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                AppLocalizations.of(context).lessonPreviewContextExample,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(word.exampleSentence),
          const SizedBox(height: AppTokens.s4),
          Text(
            word.exampleTranslation,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MiniWordRow extends StatelessWidget {
  const _MiniWordRow({
    required this.word,
    required this.isCurrent,
    required this.isChecked,
    required this.onTap,
  });

  final Word word;
  final bool isCurrent;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isCurrent ? AppTokens.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                ImageCueBadge(cue: word.imageCue, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(word.word, style: theme.textTheme.titleMedium),
                ),
                Icon(
                  isChecked ? AppIcons.checkCircle : AppIcons.radioButtonUnchecked,
                  color: isChecked
                      ? AppTokens.azure
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
