import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/pinyin.dart';
import '../../core/utils/quiz_localization.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../l10n/generated/app_localizations.dart';
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

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen>
    with SingleTickerProviderStateMixin {
  static const _autoAdvanceDelay = Duration(milliseconds: 1500);

  // Times the 1500ms pause before auto-advancing after a correct answer;
  // it drives no visual property, only the delay.
  late final AnimationController _autoAdvanceController;
  final _textController = TextEditingController();
  final List<QuizQuestion> _mistakes = [];
  final Set<String> _mistakeQuestionIds = {};
  final Set<String> _wrongTries = {};
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _checked = false;
  bool _lastCorrect = false;
  bool _isSubmitting = false;
  bool _lockedCorrect = false;

  @override
  void initState() {
    super.initState();
    _autoAdvanceController = AnimationController(
      vsync: this,
      duration: _autoAdvanceDelay,
    );
  }

  @override
  void dispose() {
    _autoAdvanceController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTimed = widget.mode == QuizSessionMode.timed;
    final l10n = AppLocalizations.of(context);
    final lessons = ref.watch(
      appControllerProvider.select(
        (state) => isTimed ? state.lessons : state.formalLessons,
      ),
    );
    final allLessons = ref.watch(
      appControllerProvider.select((state) => state.lessons),
    );
    final lesson = _findLesson(lessons);
    if (lesson == null) {
      return Scaffold(body: Center(child: Text(l10n.quizNoLesson)));
    }
    if (lesson.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(lesson.title)),
        body: Center(child: Text(l10n.quizNoQuestions)),
      );
    }
    final localeCode = Localizations.localeOf(context).languageCode;
    final question = localizeQuizQuestion(
      lesson.questions[_index],
      _meaningPool(allLessons),
      localeCode,
    );
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
          title: Text(isTimed ? l10n.quizTimedTest : lesson.title),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: AppProgressBar(value: progress)),
                    const SizedBox(width: 12),
                    AppPill(
                      label: '${_index + 1}/${lesson.questions.length}',
                      icon: AppIcons.flag,
                    ),
                    if (isTimed) ...[
                      const SizedBox(width: 8),
                      AppPill(
                        label: l10n.quizCampusSpeed,
                        icon: AppIcons.timer,
                        variant: PillVariant.streak,
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
                          lockedCorrect: _lockedCorrect,
                          wrongTries: _wrongTries,
                          controller: _textController,
                          onSelected: (value) =>
                              _judge(lesson, question, value),
                          onInputChanged: () => setState(() {}),
                        ),
                        if (_checked) ...[
                          const SizedBox(height: 14),
                          _FeedbackPanel(
                            isCorrect: _lastCorrect,
                            revealAnswer: _lastCorrect,
                            question: question,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (question.type == QuizQuestionType.spelling)
                  AppPrimaryButton(
                    label: l10n.quizCheck,
                    icon: AppIcons.check,
                    onPressed:
                        _hasAnswer(question) &&
                            !_lockedCorrect &&
                            !_isSubmitting
                        ? () => _submitSpelling(lesson, question)
                        : null,
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
    final l10n = AppLocalizations.of(activeContext);
    if (!_canLeaveWithoutConfirmation) {
      final confirmed = await showDialog<bool>(
        context: activeContext,
        builder: (context) => AlertDialog(
          title: Text(l10n.quizLeaveTitle),
          content: Text(l10n.quizLeaveContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.quizKeepAnswering),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(AppIcons.exitToApp),
              label: Text(l10n.commonLeave),
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

  /// Word pool used to resolve baked (Chinese) option/answer meanings to the
  /// app locale. Covers the wordbook distractors by spanning every lesson's
  /// words.
  Iterable<Word> _meaningPool(List<Lesson> lessons) {
    return [for (final lesson in lessons) ...lesson.words];
  }

  Lesson? _findLesson(List<Lesson> lessons) {
    for (final lesson in lessons) {
      if (lesson.id == widget.lessonId) return lesson;
    }
    return null;
  }

  bool _hasAnswer(QuizQuestion question) {
    if (question.type == QuizQuestionType.spelling) {
      return _textController.text.trim().isNotEmpty;
    }
    return _selected != null;
  }

  /// Records the first-attempt scoring/mistake semantics for [question] given
  /// whether this attempt was [isCorrect]. Must mirror the legacy logic exactly.
  void _recordAttempt(QuizQuestion question, bool isCorrect) {
    if (isCorrect) {
      if (!_mistakeQuestionIds.contains(question.id)) {
        _correct++;
      }
    } else if (_mistakeQuestionIds.add(question.id)) {
      _mistakes.add(question);
    }
  }

  /// Instant judgment for a tapped choice [option].
  void _judge(Lesson lesson, QuizQuestion question, String option) {
    if (_lockedCorrect) return;
    final isCorrect = option.toLowerCase() == question.answer.toLowerCase();
    setState(() {
      _recordAttempt(question, isCorrect);
      _selected = option;
      _checked = true;
      _lastCorrect = isCorrect;
      if (isCorrect) {
        _lockedCorrect = true;
      } else {
        _wrongTries.add(option);
      }
    });
    if (isCorrect) {
      _autoAdvanceController
        ..reset()
        ..forward().whenComplete(() {
          if (!mounted) return;
          _advance(lesson, question);
        });
    }
  }

  /// Submit handler for spelling questions (keeps the explicit check button).
  void _submitSpelling(Lesson lesson, QuizQuestion question) {
    if (_lockedCorrect) return;
    final answer = _textController.text.trim();
    if (answer.isEmpty) return;
    final isCorrect =
        normalizePinyin(answer) == normalizePinyin(question.answer);
    setState(() {
      _recordAttempt(question, isCorrect);
      _checked = true;
      _lastCorrect = isCorrect;
      if (isCorrect) {
        _lockedCorrect = true;
      } else {
        // Hide the feedback panel so the still-enabled field invites an
        // immediate retry (the field stays enabled via !_lockedCorrect).
        _checked = false;
      }
    });
    if (isCorrect) {
      _autoAdvanceController
        ..reset()
        ..forward().whenComplete(() {
          if (!mounted) return;
          _advance(lesson, question);
        });
    }
  }

  Future<void> _advance(Lesson lesson, QuizQuestion question) async {
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
          .completeLesson(
            result,
            isTrainingChallenge: widget.mode == QuizSessionMode.timed,
          );
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
      _lockedCorrect = false;
      _wrongTries.clear();
      _textController.clear();
    });
  }
}

class _QuestionPromptPanel extends StatelessWidget {
  const _QuestionPromptPanel({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
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
              AppPill(
                label: displayQuestionType(question.type, l10n: l10n),
                icon: _questionTypeIcon(question.type),
                variant: PillVariant.primary,
              ),
              AppPill(label: question.word.partOfSpeech),
              AppPill(
                label: displayDifficulty(question.word.difficulty, l10n: l10n),
                variant: PillVariant.streak,
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
        return AppIcons.translate;
      case QuizQuestionType.chineseChoice:
        return AppIcons.swapHoriz;
      case QuizQuestionType.contextChoice:
        return AppIcons.formatQuote;
      case QuizQuestionType.imageChoice:
        return AppIcons.imageSearch;
      case QuizQuestionType.listeningWordChoice:
      case QuizQuestionType.listeningMeaningChoice:
        return AppIcons.hearing;
      case QuizQuestionType.spelling:
        return AppIcons.edit;
      // 新题型图标：复用语义最接近的已有图标
      case QuizQuestionType.sentenceCloze:
        return AppIcons.formatQuote; // 填空与上下文题同属句子语境
      case QuizQuestionType.confusableChoice:
        return AppIcons.swapHoriz;   // 易混词辨析类似中英互选
      case QuizQuestionType.collocationChoice:
        return AppIcons.translate;   // 搭配选择偏向词义辨析
      case QuizQuestionType.derivativeChoice:
        return AppIcons.edit;        // 词形变化类似拼写题
    }
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
    required this.question,
    required this.selected,
    required this.lockedCorrect,
    required this.wrongTries,
    required this.controller,
    required this.onSelected,
    required this.onInputChanged,
  });

  final QuizQuestion question;
  final String? selected;
  final bool lockedCorrect;
  final Set<String> wrongTries;
  final TextEditingController controller;
  final ValueChanged<String> onSelected;
  final VoidCallback onInputChanged;

  @override
  Widget build(BuildContext context) {
    if (question.type == QuizQuestionType.spelling) {
      return TextField(
        controller: controller,
        enabled: !lockedCorrect,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).quizInputWord,
          prefixIcon: const Icon(AppIcons.edit),
        ),
        onChanged: (_) => onInputChanged(),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s12),
            child: WordChoiceButton(
              letter: String.fromCharCode(65 + i),
              text: question.options[i],
              state: _optionState(question.options[i]),
              onTap: lockedCorrect
                  ? null
                  : () => onSelected(question.options[i]),
            ),
          ),
      ],
    );
  }

  bool _isCorrectOption(String option) {
    return option.toLowerCase() == question.answer.toLowerCase();
  }

  ChoiceState _optionState(String option) {
    if (lockedCorrect && _isCorrectOption(option)) return ChoiceState.correct;
    if (wrongTries.contains(option)) return ChoiceState.wrong;
    return ChoiceState.idle;
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.isCorrect,
    required this.revealAnswer,
    required this.question,
  });

  final bool isCorrect;

  /// When false (wrong attempt) the panel only shows a retry hint and hides the
  /// explanation, correct word and example so retrying stays meaningful.
  final bool revealAnswer;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = isCorrect
        ? (theme.brightness == Brightness.dark
              ? theme.colorScheme.primary
              : AppTheme.success)
        : theme.colorScheme.error;
    return AppCard(
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
              isCorrect ? AppIcons.check : AppIcons.close,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  revealAnswer
                      ? '${l10n.quizCorrect}${question.explanation}'
                      : '${l10n.quizWrong}${l10n.quizRetry}',
                  style: TextStyle(color: color),
                ),
                if (revealAnswer) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.quizReinforce}${question.word.word} · ${question.word.primaryDefinitionFor(Localizations.localeOf(context).languageCode)}',
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
