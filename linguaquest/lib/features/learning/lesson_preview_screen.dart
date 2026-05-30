import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';

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
  Widget build(BuildContext context) {
    final lesson = _findLesson(ref);
    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('没有找到这节课')));
    }

    final words = lesson.words;
    final word = words.isEmpty
        ? null
        : words[_wordIndex.clamp(0, words.length - 1)];
    final selectedConfidence = word == null
        ? null
        : _confidenceByWordId[word.id];
    final progress = words.isEmpty ? 0.0 : (_wordIndex + 1) / words.length;
    final isLastWord = _wordIndex >= words.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/study/new'),
        title: const Text('新学词卡'),
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
                        label: const Text('上一张'),
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
                        label: Text(isLastWord ? '进入语境练习' : '下一张词卡'),
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
              title: '先建立理解，再做语境题',
              subtitle:
                  '${lesson.section} · ${lesson.estimatedMinutes} 分钟 · 第 ${words.isEmpty ? 0 : _wordIndex + 1}/${words.length} 张',
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.progressTrack(context),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
              ),
            ),
            const SizedBox(height: 18),
            if (word == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('暂无词卡', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('这节课还没有可学习的词。'),
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
              _ContextCard(word: word),
              const SizedBox(height: 24),
              SectionHeader(
                title: '本课词卡',
                subtitle:
                    '${lesson.xpReward} XP · ${lesson.questions.length} 道语境题',
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < words.length; index++)
                _MiniWordRow(
                  word: words[index],
                  isCurrent: index == _wordIndex,
                  isChecked: _confidenceByWordId.containsKey(words[index].id),
                  onTap: () => setState(() => _wordIndex = index),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Lesson? _findLesson(WidgetRef ref) {
    for (final lesson in ref.watch(appControllerProvider).lessons) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageCueBadge(cue: word.imageCue, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.word, style: theme.textTheme.headlineSmall),
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
          const SizedBox(height: 18),
          Text(word.meaning, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
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
    final items = [
      ('认识', Icons.sentiment_satisfied_alt_outlined, AppTheme.teal),
      ('模糊', Icons.visibility_outlined, AppTheme.mango),
      ('不认识', Icons.help_outline, AppTheme.coral),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('先判断熟悉度', style: Theme.of(context).textTheme.titleMedium),
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

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('语境例句', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(word.exampleSentence),
          const SizedBox(height: 6),
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
