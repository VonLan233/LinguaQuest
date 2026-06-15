import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/quest_panel.dart';
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
      return Scaffold(
        body: Center(child: Text(l10n.lessonPreviewNoLesson)),
      );
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _wordIndex == 0
                              ? null
                              : () => setState(() => _wordIndex--),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(l10n.lessonPreviewPrevious),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
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
                          icon: Icon(
                            isLastWord
                                ? Icons.play_arrow_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(
                            isLastWord
                                ? l10n.lessonPreviewEnterContext
                                : l10n.lessonPreviewNextCard,
                          ),
                        ),
                      ),
                    ],
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
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppTheme.progressTrack(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.teal,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (word == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.lessonPreviewNoCards,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.lessonPreviewNoCardsBody),
                    ],
                  ),
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
              icon: const Icon(Icons.exit_to_app_rounded),
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
    return QuestPanel(
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
                        PillLabel(label: word.partOfSpeech),
                        PillLabel(
                          label: displayDifficulty(word.difficulty),
                          color: AppTheme.coral,
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
            word.meaning,
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
      (l10n.studyRecallKnown, Icons.sentiment_satisfied_alt_outlined, AppTheme.teal),
      (l10n.studyRecallFuzzy, Icons.visibility_outlined, AppTheme.mango),
      (l10n.studyRecallUnknown, Icons.help_outline, AppTheme.coral),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.lessonPreviewAssessFirst, style: Theme.of(context).textTheme.titleMedium),
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
        backgroundColor: selected ? color.withValues(alpha: 0.12) : null,
        side: BorderSide(
          color: selected
              ? color
              : Theme.of(context).colorScheme.outlineVariant,
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
    return QuestPanel(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
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
        color: isCurrent ? AppTheme.accentSurface(context) : Colors.transparent,
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
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isChecked
                      ? AppTheme.success
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
