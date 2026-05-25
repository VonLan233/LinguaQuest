import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  const QuizSessionScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  final _textController = TextEditingController();
  final List<QuizQuestion> _mistakes = [];
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _checked = false;
  bool _lastCorrect = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('Lesson not found')));
    }
    final question = lesson.questions[_index];
    final progress = (_index + 1) / lesson.questions.length;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 14),
              Text(
                'Question ${_index + 1}/${lesson.questions.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.prompt,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
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
                        const SizedBox(height: 18),
                        _FeedbackPanel(
                          isCorrect: _lastCorrect,
                          explanation: question.explanation,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _canContinue(question)
                    ? () => _handlePrimary(lesson, question)
                    : null,
                icon: Icon(_checked ? Icons.arrow_forward : Icons.check),
                label: Text(_checked ? 'Continue' : 'Check'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Lesson? get _lesson {
    final lessons = ref.read(appControllerProvider).lessons;
    for (final lesson in lessons) {
      if (lesson.id == widget.lessonId) return lesson;
    }
    return null;
  }

  bool _canContinue(QuizQuestion question) {
    if (_checked) return true;
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
        if (isCorrect) {
          _correct++;
        } else {
          _mistakes.add(question);
        }
      });
      return;
    }

    if (_index == lesson.questions.length - 1) {
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
      await ref.read(appControllerProvider.notifier).completeLesson(result);
      if (!mounted) return;
      context.go('/lesson/${lesson.id}/result', extra: result);
      return;
    }

    setState(() {
      _index++;
      _selected = null;
      _checked = false;
      _lastCorrect = false;
      _textController.clear();
    });
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
          labelText: 'Type the word',
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
              child: OutlinedButton(
                onPressed: checked ? null : () => onSelected(option),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected == option
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(option),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.isCorrect, required this.explanation});

  final bool isCorrect;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? 'Correct. $explanation' : 'Not yet. $explanation',
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
