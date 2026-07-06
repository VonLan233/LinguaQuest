import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/answer_sound_service.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/pinyin.dart';
import '../../core/utils/quiz_localization.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/pronunciation_controls.dart';
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

  // A wrong answer stays retryable, but only up to this many wrong attempts;
  // then the question locks, reveals the answer and auto-advances so learners
  // cannot brute-force by tapping every option until one is correct.
  static const _maxWrongAttempts = 2;

  // Times the 1500ms pause before auto-advancing after a correct answer;
  // it drives no visual property, only the delay.
  late final AnimationController _autoAdvanceController;
  final _textController = TextEditingController();
  final List<QuizQuestion> _mistakes = [];
  final Set<String> _mistakeQuestionIds = {};
  final Set<String> _wrongTries = {};
  int _index = 0;
  int _correct = 0;
  int _wrongCount = 0;
  String? _selected;
  bool _checked = false;
  bool _isSubmitting = false;
  bool _locked = false;

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
    final currentLanguage = ref.watch(
      appControllerProvider.select((state) => state.currentLanguage),
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
          title: Text(lesson.title),
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
                // The question is centered in the available space so it stays
                // readable; the options are anchored to the bottom of the
                // screen for easy reach.
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: QuizPromptPanel(
                        question: question,
                        language: currentLanguage,
                      ),
                    ),
                  ),
                ),
                // Correctness is conveyed by option colors and answer sound,
                // keeping the prompt and options visible on compact screens.
                _QuestionInput(
                  question: question,
                  selected: _selected,
                  locked: _locked,
                  wrongTries: _wrongTries,
                  controller: _textController,
                  onSelected: (value) => _judge(lesson, question, value),
                  onInputChanged: () => setState(() {}),
                ),
                if (question.type == QuizQuestionType.spelling) ...[
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: l10n.quizCheck,
                    icon: AppIcons.check,
                    onPressed:
                        _hasAnswer(question) && !_locked && !_isSubmitting
                        ? () => _submitSpelling(lesson, question)
                        : null,
                  ),
                ],
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

  /// Whether [wrongAttempts] wrong tries exhausts the retry budget for
  /// [question]. Choice questions also lock once every distractor has been
  /// tried, so the correct option can never be reached by elimination.
  bool _reachedAttemptLimit(QuizQuestion question, int wrongAttempts) {
    final distractors = question.options.length - 1;
    final limit = distractors > 0 && distractors < _maxWrongAttempts
        ? distractors
        : _maxWrongAttempts;
    return wrongAttempts >= limit;
  }

  /// Instant judgment for a tapped choice [option].
  void _judge(Lesson lesson, QuizQuestion question, String option) {
    if (_locked) return;
    final isCorrect =
        option.trim().toLowerCase() == question.answer.trim().toLowerCase();
    unawaited(
      AnswerSoundService.play(
        isCorrect: isCorrect,
        enabled: ref.read(appControllerProvider).sensorySettings.soundEnabled,
      ),
    );
    setState(() {
      _recordAttempt(question, isCorrect);
      _selected = option;
      _checked = true;
      if (isCorrect) {
        _locked = true;
      } else if (_wrongTries.add(option)) {
        // Only a distinct distractor consumes the retry budget, so repeatedly
        // tapping the same wrong option can't fast-track the reveal.
        _wrongCount++;
        if (_reachedAttemptLimit(question, _wrongCount)) _locked = true;
      }
    });
    if (_locked) {
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
    if (_locked) return;
    final answer = _textController.text.trim();
    if (answer.isEmpty) return;
    final isCorrect =
        normalizePinyin(answer) == normalizePinyin(question.answer);
    unawaited(
      AnswerSoundService.play(
        isCorrect: isCorrect,
        enabled: ref.read(appControllerProvider).sensorySettings.soundEnabled,
      ),
    );
    final exhausted =
        !isCorrect && _reachedAttemptLimit(question, _wrongCount + 1);
    setState(() {
      _recordAttempt(question, isCorrect);
      _checked = true;
      if (isCorrect) {
        _locked = true;
      } else {
        _wrongCount++;
        if (exhausted) {
          _locked = true;
        } else {
          // Hide the feedback panel so the still-enabled field invites an
          // immediate retry (the field stays enabled via !_locked).
          _checked = false;
        }
      }
    });
    if (isCorrect || exhausted) {
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
      _locked = false;
      _wrongCount = 0;
      _wrongTries.clear();
      _textController.clear();
    });
  }
}

class QuizPromptPanel extends StatelessWidget {
  const QuizPromptPanel({
    required this.question,
    this.language = '',
    super.key,
  });

  final QuizQuestion question;
  final String language;

  /// True for question types whose answer IS the target word/character, so
  /// showing the cue badge (the character) would leak the answer — e.g. the
  /// Campus Sprint "Select the Chinese word for: …" (chineseChoice).
  bool get _cueRevealsAnswer {
    switch (question.type) {
      case QuizQuestionType.chineseChoice:
      case QuizQuestionType.listeningWordChoice:
      case QuizQuestionType.sentenceCloze:
      case QuizQuestionType.confusableChoice:
      case QuizQuestionType.collocationChoice:
      case QuizQuestionType.derivativeChoice:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        children: [
          ImageCueBadge(
            cue: question.word.imageCue,
            size: 104,
            icon: _cueRevealsAnswer ? AppIcons.help : null,
          ),
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
          if (question.type == QuizQuestionType.listeningWordChoice ||
              question.type == QuizQuestionType.listeningMeaningChoice) ...[
            const SizedBox(height: 12),
            PronunciationControls(
              word: question.word.word,
              audioUKUrl: question.word.audioUKUrl,
              audioUSUrl: question.word.audioUSUrl,
              language: language,
            ),
          ],
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
        return AppIcons.swapHoriz; // 易混词辨析类似中英互选
      case QuizQuestionType.collocationChoice:
        return AppIcons.translate; // 搭配选择偏向词义辨析
      case QuizQuestionType.derivativeChoice:
        return AppIcons.edit; // 词形变化类似拼写题
    }
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
    required this.question,
    required this.selected,
    required this.locked,
    required this.wrongTries,
    required this.controller,
    required this.onSelected,
    required this.onInputChanged,
  });

  final QuizQuestion question;
  final String? selected;
  final bool locked;
  final Set<String> wrongTries;
  final TextEditingController controller;
  final ValueChanged<String> onSelected;
  final VoidCallback onInputChanged;

  @override
  Widget build(BuildContext context) {
    if (question.type == QuizQuestionType.spelling) {
      return TextField(
        controller: controller,
        enabled: !locked,
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
              onTap: locked ? null : () => onSelected(question.options[i]),
            ),
          ),
      ],
    );
  }

  bool _isCorrectOption(String option) {
    return option.trim().toLowerCase() == question.answer.trim().toLowerCase();
  }

  ChoiceState _optionState(String option) {
    if (locked && _isCorrectOption(option)) return ChoiceState.correct;
    if (wrongTries.contains(option)) return ChoiceState.wrong;
    return ChoiceState.idle;
  }
}
