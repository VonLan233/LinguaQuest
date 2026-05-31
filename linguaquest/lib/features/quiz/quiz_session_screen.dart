import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import 'lesson_result_screen.dart';

enum QuizSessionMode { lesson, timed }

class QuizSessionScreen extends ConsumerStatefulWidget {
  const QuizSessionScreen({
    required this.lessonId,
    this.mode = QuizSessionMode.lesson,
    super.key,
  });

  final String lessonId;
  final QuizSessionMode mode;

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  static const _feedbackHoldDuration = Duration(milliseconds: 500);

  final _textController = TextEditingController();
  final List<QuizQuestion> _mistakes = [];
  final Set<String> _mistakeQuestionIds = {};
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _checked = false;
  bool _lastCorrect = false;
  bool _isSubmitting = false;
  bool _feedbackReady = true;
  int _feedbackHoldToken = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTimed = widget.mode == QuizSessionMode.timed;
    final lessons = ref.watch(
      appControllerProvider.select(
        (state) => isTimed ? state.lessons : state.formalLessons,
      ),
    );
    final lesson = _findLesson(lessons);
    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('没有找到这节课')));
    }
    if (lesson.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: const Center(child: Text('这节课还没有测验。')),
      );
    }
    final question = lesson.questions[_index];
    final progress = (_index + 1) / lesson.questions.length;

    return PopScope(
      canPop: _canLeaveWithoutConfirmation,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleBack(context)),
          title: Text(isTimed ? '限时测试' : lesson.title),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: AppTheme.progressTrack(context),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.teal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PillLabel(
                      label: '${_index + 1}/${lesson.questions.length}',
                      icon: Icons.flag_outlined,
                    ),
                    if (isTimed) ...[
                      const SizedBox(width: 8),
                      const PillLabel(
                        label: '校园速测',
                        icon: Icons.timer_outlined,
                        color: AppTheme.coral,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuestionPromptPanel(question: question),
                        const SizedBox(height: 18),
                        _QuestionInput(
                          question: question,
                          selected: _selected,
                          checked: _checked,
                          controller: _textController,
                          onSelected: (value) =>
                              setState(() => _selected = value),
                          onInputChanged: () => setState(() {}),
                        ),
                        if (_checked) ...[
                          const SizedBox(height: 14),
                          _FeedbackPanel(
                            isCorrect: _lastCorrect,
                            question: question,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _canUsePrimaryAction(question) && !_isSubmitting
                      ? () => _handlePrimary(lesson, question)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _checked && !_lastCorrect
                        ? Theme.of(context).colorScheme.error
                        : null,
                    foregroundColor: _checked && !_lastCorrect
                        ? Theme.of(context).colorScheme.onError
                        : null,
                  ),
                  icon: Icon(
                    _checked
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(_checked ? (_lastCorrect ? '继续' : '再试一次') : '检查'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canLeaveWithoutConfirmation {
    if (_isSubmitting) return true;
    return _index == 0 &&
        !_checked &&
        _selected == null &&
        _textController.text.trim().isEmpty &&
        _correct == 0 &&
        _mistakes.isEmpty;
  }

  Future<void> _handleBack(BuildContext activeContext) async {
    if (!_canLeaveWithoutConfirmation) {
      final confirmed = await showDialog<bool>(
        context: activeContext,
        builder: (context) => AlertDialog(
          title: const Text('离开测验？'),
          content: const Text('当前测验进度将被放弃。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续答题'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('离开'),
            ),
          ],
        ),
      );
      if (confirmed != true || !activeContext.mounted) return;
      setState(() => _isSubmitting = true);
      await Future<void>.delayed(Duration.zero);
    }

    if (!activeContext.mounted) return;
    if (activeContext.canPop()) {
      activeContext.pop();
      return;
    }
    activeContext.go(_fallbackExitRoute);
  }

  String get _fallbackExitRoute =>
      widget.mode == QuizSessionMode.timed ? '/training' : '/learn';

  Lesson? _findLesson(List<Lesson> lessons) {
    for (final lesson in lessons) {
      if (lesson.id == widget.lessonId) return lesson;
    }
    return null;
  }

  bool _canUsePrimaryAction(QuizQuestion question) {
    if (_checked) return _feedbackReady;
    return _hasAnswer(question);
  }

  bool _hasAnswer(QuizQuestion question) {
    if (question.type == QuizQuestionType.spelling) {
      return _textController.text.trim().isNotEmpty;
    }
    return _selected != null;
  }

  Future<void> _handlePrimary(Lesson lesson, QuizQuestion question) async {
    if (!_checked) {
      final answer = question.type == QuizQuestionType.spelling
          ? _textController.text.trim()
          : _selected;
      final isCorrect = answer?.toLowerCase() == question.answer.toLowerCase();
      setState(() {
        _checked = true;
        _lastCorrect = isCorrect;
        _feedbackReady = false;
        if (isCorrect) {
          if (!_mistakeQuestionIds.contains(question.id)) {
            _correct++;
          }
        } else if (_mistakeQuestionIds.add(question.id)) {
          _mistakes.add(question);
        }
      });
      _holdFeedback();
      return;
    }

    if (!_lastCorrect) {
      setState(() {
        _checked = false;
        _selected = null;
        _feedbackReady = true;
        _feedbackHoldToken++;
      });
      return;
    }

    if (_index == lesson.questions.length - 1) {
      if (_isSubmitting) return;
      final result = LessonResult(
        lessonId: lesson.id,
        lessonTitle: lesson.title,
        totalQuestions: lesson.questions.length,
        correctAnswers: _correct,
        xpEarned: (_correct / lesson.questions.length * lesson.xpReward)
            .round(),
        mistakes: List.unmodifiable(_mistakes),
        completedAt: DateTime.now(),
      );
      setState(() => _isSubmitting = true);
      final succeeded = await ref
          .read(appControllerProvider.notifier)
          .completeLesson(result);
      if (!mounted) return;
      if (!succeeded) {
        setState(() => _isSubmitting = false);
        return;
      }
      context.go(
        '/lesson/${lesson.id}/result',
        extra: LessonResultViewArgs(
          result: result,
          source: widget.mode == QuizSessionMode.timed
              ? LessonResultSource.timed
              : LessonResultSource.lesson,
        ),
      );
      return;
    }

    setState(() {
      _index++;
      _selected = null;
      _checked = false;
      _lastCorrect = false;
      _feedbackReady = true;
      _feedbackHoldToken++;
      _textController.clear();
    });
  }

  void _holdFeedback() {
    final token = ++_feedbackHoldToken;
    Future<void>.delayed(_feedbackHoldDuration, () {
      if (!mounted || token != _feedbackHoldToken) return;
      setState(() => _feedbackReady = true);
    });
  }
}

class _QuestionPromptPanel extends StatelessWidget {
  const _QuestionPromptPanel({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ImageCueBadge(cue: question.word.imageCue, size: 104),
          const SizedBox(height: 14),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              PillLabel(
                label: displayQuestionType(question.type),
                icon: _questionTypeIcon(question.type),
                color: AppTheme.cyan,
              ),
              PillLabel(label: question.word.partOfSpeech),
              PillLabel(
                label: displayDifficulty(question.word.difficulty),
                color: AppTheme.coral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _questionTypeIcon(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.meaningChoice:
        return Icons.translate_outlined;
      case QuizQuestionType.chineseChoice:
        return Icons.swap_horiz_rounded;
      case QuizQuestionType.contextChoice:
        return Icons.format_quote_outlined;
      case QuizQuestionType.imageChoice:
        return Icons.image_search_outlined;
      case QuizQuestionType.spelling:
        return Icons.edit_outlined;
    }
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
    required this.question,
    required this.selected,
    required this.checked,
    required this.controller,
    required this.onSelected,
    required this.onInputChanged,
  });

  final QuizQuestion question;
  final String? selected;
  final bool checked;
  final TextEditingController controller;
  final ValueChanged<String> onSelected;
  final VoidCallback onInputChanged;

  @override
  Widget build(BuildContext context) {
    if (question.type == QuizQuestionType.spelling) {
      return TextField(
        controller: controller,
        enabled: !checked,
        decoration: const InputDecoration(
          labelText: '输入单词',
          prefixIcon: Icon(Icons.edit_outlined),
        ),
        onChanged: (_) => onInputChanged(),
      );
    }

    return Column(
      children: [
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 66,
              child: OutlinedButton(
                onPressed: checked ? () {} : () => onSelected(option),
                style: OutlinedButton.styleFrom(
                  splashFactory: checked ? NoSplash.splashFactory : null,
                  overlayColor: checked ? Colors.transparent : null,
                  enabledMouseCursor: checked ? SystemMouseCursors.basic : null,
                  backgroundColor: _optionBackground(context, option),
                  foregroundColor: _optionForeground(context, option),
                  side: BorderSide(
                    color: _optionBorder(context, option),
                    width: selected == option || _isCorrectOption(option)
                        ? 2
                        : 1,
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (checked && selected == option)
                      Icon(
                        _isCorrectOption(option)
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                      ),
                    if (checked &&
                        selected != option &&
                        _isCorrectOption(option))
                      const Icon(Icons.check_circle_outline),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isCorrectOption(String option) {
    return option.toLowerCase() == question.answer.toLowerCase();
  }

  Color _optionBackground(BuildContext context, String option) {
    if (!checked) {
      return selected == option
          ? AppTheme.selectedSurface(context)
          : Theme.of(context).colorScheme.surface;
    }
    if (_isCorrectOption(option)) {
      return _successColor(context).withValues(alpha: 0.12);
    }
    if (selected == option) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.12);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _optionForeground(BuildContext context, String option) {
    if (!checked) return Theme.of(context).colorScheme.onSurface;
    if (_isCorrectOption(option)) return _successColor(context);
    if (selected == option) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _optionBorder(BuildContext context, String option) {
    if (!checked) {
      return selected == option
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outlineVariant;
    }
    if (_isCorrectOption(option)) return _successColor(context);
    if (selected == option) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.outlineVariant;
  }

  Color _successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary
        : AppTheme.success;
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.isCorrect, required this.question});

  final bool isCorrect;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect
        ? (theme.brightness == Brightness.dark
              ? theme.colorScheme.primary
              : AppTheme.success)
        : theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect
                      ? '答对了。${question.explanation}'
                      : '还不对。${question.explanation}',
                  style: TextStyle(color: color),
                ),
                if (isCorrect) ...[
                  const SizedBox(height: 8),
                  Text(
                    '强化记忆：${question.word.word} · ${question.word.meaning}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (question.word.exampleSentence.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      question.word.exampleSentence,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
