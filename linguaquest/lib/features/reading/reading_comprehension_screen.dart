import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/article.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';
import 'quiz_question_kind.dart';

/// Reading-comprehension flow (P3e).
///
/// Runs over [Article.comprehension] (a `List<QuizQuestion>`) reusing the quiz
/// choice UI primitives (`QuizPromptPanel`/`WordChoiceButton`-style buttons +
/// immediate feedback). On completion records a `ReadingResult` + `StudySession`
/// via `completeReading`, shows a score summary, and pops with `true`.
class ReadingComprehensionSheet extends ConsumerStatefulWidget {
  const ReadingComprehensionSheet({required this.article, super.key});

  final Article article;

  @override
  ConsumerState<ReadingComprehensionSheet> createState() =>
      _ReadingComprehensionSheetState();
}

class _ReadingComprehensionSheetState
    extends ConsumerState<ReadingComprehensionSheet> {
  late final List<QuizQuestion> _questions = widget.article.comprehension;
  final DateTime _startedAt = DateTime.now();

  int _index = 0;
  String? _selected;
  bool _checked = false;
  bool _finished = false;
  bool _submitting = false;

  // One entry per question (true = answered correctly on first attempt).
  late final List<bool> _correctness = List<bool>.filled(
    _questions.length,
    false,
  );

  void _judge(String option) {
    if (_checked) return;
    final question = _questions[_index];
    final isCorrect = option.toLowerCase() == question.answer.toLowerCase();
    setState(() {
      _selected = option;
      _checked = true;
      _correctness[_index] = isCorrect;
    });
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _checked = false;
      });
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final perKind = <String, int>{};
    for (var i = 0; i < _questions.length; i++) {
      if (_correctness[i]) {
        final kind = comprehensionKind(_questions[i]);
        perKind[kind] = (perKind[kind] ?? 0) + 1;
      }
    }
    await ref.read(appControllerProvider.notifier).completeReading(
          article: widget.article,
          questions: _questions,
          correctness: _correctness,
          perKindCorrect: perKind,
          startedAt: _startedAt,
        );
    if (!mounted) return;
    setState(() {
      _finished = true;
      _submitting = false;
    });
  }

  int get _correctCount => _correctness.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_questions.isEmpty) {
      return _Frame(
        title: l10n.readingComprehensionTitle,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: Text(
            l10n.readingComprehensionEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_finished) {
      return _Frame(
        title: l10n.readingComprehensionResultTitle,
        child: _ResultView(
          correct: _correctCount,
          total: _questions.length,
          onDone: () => Navigator.of(context).pop(true),
        ),
      );
    }

    final question = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    final isLast = _index == _questions.length - 1;

    return _Frame(
      title: l10n.readingComprehensionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: AppProgressBar(value: progress)),
              const SizedBox(width: AppTokens.s12),
              AppPill(
                label: '${_index + 1}/${_questions.length}',
                icon: AppIcons.flag,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (question.promptEn != null) ...[
                  const SizedBox(height: AppTokens.s4),
                  Text(
                    question.promptEn!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s12),
              child: WordChoiceButton(
                letter: String.fromCharCode(65 + i),
                text: question.optionsEn != null && i < question.optionsEn!.length
                    ? '${question.options[i]}  ·  ${question.optionsEn![i]}'
                    : question.options[i],
                state: _optionState(question, question.options[i]),
                onTap: _checked ? null : () => _judge(question.options[i]),
              ),
            ),
          if (_checked) ...[
            const SizedBox(height: AppTokens.s8),
            _FeedbackCard(
              isCorrect: _correctness[_index],
              explanation: question.explanationEn != null
                  ? '${question.explanation}\n${question.explanationEn!}'
                  : question.explanation,
              answer: question.answer,
            ),
            const SizedBox(height: AppTokens.s16),
            AppPrimaryButton(
              key: const ValueKey('reading-comprehension-next'),
              label: isLast
                  ? l10n.readingComprehensionFinish
                  : l10n.readingComprehensionNext,
              icon: isLast ? AppIcons.check : AppIcons.arrowForward,
              onPressed: _submitting ? null : _next,
            ),
          ],
        ],
      ),
    );
  }

  ChoiceState _optionState(QuizQuestion question, String option) {
    if (!_checked) return ChoiceState.idle;
    final isCorrectOption =
        option.toLowerCase() == question.answer.toLowerCase();
    if (isCorrectOption) return ChoiceState.correct;
    if (option == _selected) return ChoiceState.wrong;
    return ChoiceState.idle;
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s20,
          AppTokens.s8,
          AppTokens.s20,
          AppTokens.s20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTokens.s12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.isCorrect,
    required this.explanation,
    required this.answer,
  });

  final bool isCorrect;
  final String explanation;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = isCorrect ? AppTokens.success : theme.colorScheme.error;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCorrect ? AppIcons.check : AppIcons.close, color: color),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? l10n.quizCorrect : l10n.quizWrong,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Text(answer, style: theme.textTheme.bodyMedium),
                ],
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(explanation, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.correct,
    required this.total,
    required this.onDone,
  });

  final int correct;
  final int total;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCard(
          child: Column(
            children: [
              Icon(AppIcons.check, color: AppTokens.success, size: 40),
              const SizedBox(height: AppTokens.s12),
              Text(
                l10n.readingComprehensionScore(correct, total),
                key: const ValueKey('reading-comprehension-score'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTokens.s8),
              AppPill(
                label: l10n.readingComprehensionAccuracy(pct),
                variant: PillVariant.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        AppPrimaryButton(
          key: const ValueKey('reading-comprehension-done'),
          label: l10n.readingComprehensionDone,
          icon: AppIcons.check,
          onPressed: onDone,
        ),
      ],
    );
  }
}
