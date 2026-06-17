import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session/session_queue_builder.dart';

class MixedStudySessionScreen extends ConsumerStatefulWidget {
  const MixedStudySessionScreen({required this.mode, super.key});

  final StudySessionEntryMode mode;

  @override
  ConsumerState<MixedStudySessionScreen> createState() =>
      _MixedStudySessionScreenState();
}

class _MixedStudySessionScreenState
    extends ConsumerState<MixedStudySessionScreen>
    with SingleTickerProviderStateMixin {
  static const _builder = StudySessionQueueBuilder();
  static const _autoAdvanceDelay = Duration(milliseconds: 1500);

  final Random _random = Random();
  final List<StudySessionQueueItem> _queue = [];
  final List<StudyAnswerLog> _answerLogs = [];
  final Set<String> _wrongItemIds = {};
  final Set<String> _scheduledWrongIds = {};
  final Set<String> _wrongTries = {};
  late final DateTime _sessionStartedAt;
  // Times the 1500ms pause before auto-advancing once a question step is
  // settled; it drives no visual property, only the delay.
  late final AnimationController _autoAdvanceController;
  DateTime _itemStartedAt = DateTime.now();
  StudySessionQueuePlan? _plan;
  bool _checked = false;
  bool _lastCorrect = false;
  bool _lockedCorrect = false;
  bool _isSubmitting = false;
  int _completedItems = 0;
  int _correctAnswers = 0;
  int _confidence = 3;
  List<String> _currentOptions = const [];

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _autoAdvanceController = AnimationController(
      vsync: this,
      duration: _autoAdvanceDelay,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeQueue());
  }

  @override
  void dispose() {
    _autoAdvanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = _queue.isEmpty ? null : _queue.first;
    final total = _completedItems + _queue.length;
    final progress = total == 0
        ? 1.0
        : (_completedItems / total).clamp(0.0, 1.0).toDouble();

    return PopScope(
      canPop: !_hasProgress && !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleExit(context)),
          title: Text(_titleFor(l10n)),
          actions: [
            if (widget.mode == StudySessionEntryMode.reviewOnly)
              TextButton(
                onPressed: _isSubmitting ? null : () => context.push('/review'),
                child: Text(l10n.mixedManageReviewQueue),
              ),
            if (_plan != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: AppPill(
                    label: l10n.mixedReviewRatio(
                      '${(_plan!.reviewTargetRatio * 100).round()}',
                    ),
                    icon: AppIcons.shuffle,
                    variant: PillVariant.primary,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: current == null
              ? _CompleteView(
                  hasProgress: _hasProgress,
                  onFinish: _finishAndLeave,
                  isSubmitting: _isSubmitting,
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppProgressBar(value: progress, height: 11),
                          ),
                          const SizedBox(width: 12),
                          AppPill(
                            label: '${_completedItems + 1}/$total',
                            icon: AppIcons.autoAwesomeMotion,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child:
                            current.step == StudySessionStep.understanding ||
                                current.isKnowledgeCard
                            ? _KnowledgeCardStep(
                                item: current,
                                showAssessment:
                                    current.step ==
                                    StudySessionStep.understanding,
                                selectedConfidence: _confidence,
                                isSubmitting: _isSubmitting,
                                onConfidenceChanged: (value) =>
                                    setState(() => _confidence = value),
                                onContinue: () => _continueFromCard(current),
                              )
                            : _QuestionStep(
                                item: current,
                                options: _currentOptions,
                                checked: _checked,
                                lastCorrect: _lastCorrect,
                                lockedCorrect: _lockedCorrect,
                                wrongTries: _wrongTries,
                                onSelected: (value) =>
                                    _judgeQuestion(current, value),
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations l10n) {
    switch (widget.mode) {
      case StudySessionEntryMode.newOnly:
        return l10n.mixedTitleNew;
      case StudySessionEntryMode.reviewOnly:
        return l10n.mixedTitleReview;
      case StudySessionEntryMode.mixed:
        return l10n.mixedTitleMixed;
    }
  }

  bool get _hasProgress => _completedItems > 0 || _answerLogs.isNotEmpty;

  void _initializeQueue() {
    final state = ref.read(appControllerProvider);
    final dailyGoal = state.dailyNewTarget;
    final newWords = state.currentLesson?.words ?? const <Word>[];
    final plan = _builder.build(
      newWords: newWords,
      dueWords: state.dueWords,
      weakWords: state.weakWords,
      dailyGoal: dailyGoal,
      mode: widget.mode,
    );
    if (!mounted) return;
    final firstItem = plan.items.isEmpty ? null : plan.items.first;
    final options = firstItem != null
        ? _buildOptionsFor(firstItem, state)
        : const <String>[];
    setState(() {
      _plan = plan;
      _queue
        ..clear()
        ..addAll(plan.items);
      _currentOptions = options;
      _confidence = 3;
      _itemStartedAt = DateTime.now();
    });
  }

  Future<void> _continueFromCard(StudySessionQueueItem item) async {
    if (_isSubmitting) return;
    if (item.step == StudySessionStep.understanding) {
      _applySelfAssessment(item);
    }
    _advanceCurrent();
  }

  /// Immediate judgment for a tapped choice [answer] on a question step.
  ///
  /// Mirrors the legacy two-press evaluation/logging/scheduling, but moves the
  /// trigger from a check button to the option tap:
  /// - Correct: lock, count, then auto-advance after [_autoAdvanceDelay].
  /// - Wrong + review item: recorded/persisted once, then auto-advance.
  /// - Wrong + non-review item: marked red, stays tappable for re-select.
  Future<void> _judgeQuestion(
    StudySessionQueueItem item,
    String answer,
  ) async {
    // Ignore taps while a settle/persist is in flight, or once a correct (or
    // settled review) answer has locked the step.
    if (_isSubmitting || _lockedCorrect || (_checked && item.isReview)) return;
    final isCorrect =
        answer.trim().toLowerCase() == item.meaning.trim().toLowerCase();
    final responseTime = DateTime.now()
        .difference(_itemStartedAt)
        .inMilliseconds;
    _answerLogs.add(
      StudyAnswerLog(
        itemId: item.id,
        wordId: item.wordId,
        source: item.source,
        step: item.step,
        isCorrect: isCorrect,
        responseTimeMs: responseTime,
        confidence: _confidence,
        selectedAnswer: answer,
        wrongOption: isCorrect ? null : answer,
        answeredAt: DateTime.now(),
      ),
    );
    if (!isCorrect) {
      _wrongItemIds.add(item.wordId);
      _scheduleWrongRecycle(item);
    }
    setState(() {
      _checked = true;
      _lastCorrect = isCorrect;
      if (isCorrect) {
        _lockedCorrect = true;
      } else {
        _wrongTries.add(answer);
      }
    });

    if (isCorrect) {
      if (!_wrongItemIds.contains(item.wordId)) {
        _correctAnswers += 1;
      }
    }

    if (item.isReview && item.affectsSchedule) {
      // Review items are recorded on the first attempt (no retry). Persist now;
      // _persistReviewAttempt toggles _isSubmitting so taps stay ignored while
      // the write is in flight.
      await _persistReviewAttempt(item, isCorrect, responseTime, answer);
      if (!mounted) return;
    }

    // Auto-advance whenever the item is settled: a correct answer, or a review
    // item that has now been answered. Non-review wrong answers stay for
    // re-selection.
    final settled = isCorrect || item.isReview;
    if (settled) {
      _autoAdvanceController
        ..reset()
        ..forward().whenComplete(() {
          if (!mounted || _isSubmitting) return;
          _advanceCurrent();
        });
    }
  }

  Future<void> _persistReviewAttempt(
    StudySessionQueueItem item,
    bool isCorrect,
    int responseTime,
    String answer,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      final succeeded = await ref
          .read(appControllerProvider.notifier)
          .reviewWord(
            item.wordId,
            isCorrect,
            dimension: ReviewDimension.confidence,
            answerTimeMs: responseTime,
            confidence: _confidence,
            wrongOption: isCorrect ? null : answer,
          );
      if (!mounted) return;
      if (!succeeded) {
        _showSubmitError(AppLocalizations.of(context).mixedSaveReviewFailed);
      }
    } catch (_) {
      if (mounted) {
        _showSubmitError(AppLocalizations.of(context).mixedSaveReviewFailed);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _applySelfAssessment(StudySessionQueueItem item) {
    final extraRepeats = switch (_confidence) {
      5 => 0,
      3 || 4 => 1,
      _ => 2,
    };
    for (var index = 0; index < extraRepeats; index++) {
      final recall = item.copyWith(
        step: StudySessionStep.shortRecall,
        attempt: item.attempt + index + 2,
        affectsSchedule: false,
      );
      final insertAt = min(_queue.length, 4 + index * 2);
      _queue.insert(insertAt, recall);
    }
  }

  void _scheduleWrongRecycle(StudySessionQueueItem item) {
    if (!_scheduledWrongIds.add('${item.id}:${item.attempt}')) return;
    final remaining = _queue.length <= 1
        ? <StudySessionQueueItem>[]
        : _queue.sublist(1);
    final requeued = _builder.requeueWrongAnswer(
      remaining,
      item,
      answeredCount: _completedItems,
    );
    _queue
      ..removeRange(1, _queue.length)
      ..addAll(requeued);
  }

  void _advanceCurrent() {
    final state = ref.read(appControllerProvider);
    if (_queue.isNotEmpty) _queue.removeAt(0);
    final nextItem = _queue.isEmpty ? null : _queue.first;
    final options = nextItem != null
        ? _buildOptionsFor(nextItem, state)
        : const <String>[];
    setState(() {
      _completedItems += 1;
      _checked = false;
      _lastCorrect = false;
      _lockedCorrect = false;
      _wrongTries.clear();
      _confidence = 3;
      _currentOptions = options;
      _itemStartedAt = DateTime.now();
    });
  }

  List<String> _buildOptionsFor(StudySessionQueueItem item, AppState state) {
    final answerKey = item.meaning.trim().toLowerCase();
    final seen = <String>{answerKey};
    final distractorPool = <String>[];

    void addDistractor(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return;
      final key = cleaned.toLowerCase();
      if (seen.add(key)) distractorPool.add(cleaned);
    }

    for (final lesson in state.formalLessons) {
      for (final word in lesson.words) {
        if (word.id != item.wordId) addDistractor(word.meaning);
      }
    }
    for (final word in state.customWords) {
      if (word.id != item.wordId) addDistractor(word.meaning);
    }

    final options = <String>[item.meaning];
    final randomIndices = <int>{};
    final targetCount = min(3, distractorPool.length);
    while (randomIndices.length < targetCount) {
      randomIndices.add(_random.nextInt(distractorPool.length));
    }
    for (final index in randomIndices) {
      options.add(distractorPool[index]);
    }
    while (options.length < 4) {
      options.add(
        AppLocalizations.of(context).mixedUnsureOption(options.length),
      );
    }
    options.shuffle(_random);
    return List.unmodifiable(options);
  }

  Future<void> _handleExit(BuildContext activeContext) async {
    if (!_hasProgress) {
      _leave(activeContext);
      return;
    }
    final dialogL10n = AppLocalizations.of(activeContext);
    final action = await showDialog<_ExitAction>(
      context: activeContext,
      builder: (context) => AlertDialog(
        title: Text(dialogL10n.mixedSaveProgressTitle),
        content: Text(dialogL10n.mixedSaveProgressBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitAction.continueStudy),
            child: Text(dialogL10n.mixedContinueStudy),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitAction.discard),
            child: Text(dialogL10n.mixedLeaveWithoutSaving),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _ExitAction.save),
            icon: const Icon(AppIcons.save),
            label: Text(dialogL10n.mixedSaveAndLeave),
          ),
        ],
      ),
    );
    if (action == null ||
        action == _ExitAction.continueStudy ||
        !activeContext.mounted) {
      return;
    }
    if (action == _ExitAction.save) {
      final saved = await _saveSessionProgress(completeCurrentLesson: false);
      if (!activeContext.mounted || !saved) return;
    }
    _leave(activeContext);
  }

  Future<void> _finishAndLeave() async {
    if (!_hasProgress) {
      context.go('/home');
      return;
    }
    final saved = await _saveSessionProgress(completeCurrentLesson: true);
    if (!mounted) return;
    if (saved) context.go('/home');
  }

  Future<bool> _saveSessionProgress({
    required bool completeCurrentLesson,
  }) async {
    if (_isSubmitting) return false;
    setState(() => _isSubmitting = true);
    try {
      final now = DateTime.now();
      final xp = (_correctAnswers * 4).clamp(0, 80).toInt();
      final succeeded = await ref
          .read(appControllerProvider.notifier)
          .completeMixedStudySession(
            lessonId: 'daily-mixed-session',
            totalQuestions: _answerLogs.length,
            correctAnswers: _correctAnswers,
            mistakeWordIds: _wrongItemIds.toList(),
            answerEvents: [for (final log in _answerLogs) log.toJson()],
            startedAt: _sessionStartedAt,
            endedAt: now,
            completeCurrentLesson: completeCurrentLesson,
            xpEarned: xp,
          );
      if (mounted && !succeeded) {
        _showSubmitError(AppLocalizations.of(context).mixedSaveStudyFailed);
      }
      return succeeded;
    } catch (_) {
      if (mounted) {
        _showSubmitError(AppLocalizations.of(context).mixedSaveStudyFailed);
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSubmitError(String fallback) {
    final message = ref.read(appControllerProvider).errorMessage ?? fallback;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _leave(BuildContext activeContext) {
    if (activeContext.canPop()) {
      activeContext.pop();
      return;
    }
    activeContext.go('/home');
  }
}

enum _ExitAction { continueStudy, save, discard }

class _KnowledgeCardStep extends StatelessWidget {
  const _KnowledgeCardStep({
    required this.item,
    required this.showAssessment,
    required this.selectedConfidence,
    required this.isSubmitting,
    required this.onConfidenceChanged,
    required this.onContinue,
  });

  final StudySessionQueueItem item;
  final bool showAssessment;
  final int selectedConfidence;
  final bool isSubmitting;
  final ValueChanged<int> onConfidenceChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: ImageCueBadge(cue: item.imageCue, size: 92)),
              const SizedBox(height: 16),
              Text(
                item.displayWord,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.meaning,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(item.exampleSentence, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (showAssessment) ...[
                Text(
                  l10n.mixedSelfAssessHint,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppTokens.primarySoft,
                    selectedForegroundColor: AppTokens.primarySoftText,
                  ),
                  segments: [
                    ButtonSegment(value: 5, label: Text(l10n.studyRecallKnown)),
                    ButtonSegment(value: 3, label: Text(l10n.studyRecallFuzzy)),
                    ButtonSegment(
                      value: 1,
                      label: Text(l10n.studyRecallUnknown),
                    ),
                  ],
                  selected: {selectedConfidence},
                  onSelectionChanged: (values) =>
                      onConfidenceChanged(values.first),
                ),
                const SizedBox(height: 20),
              ],
              AppPrimaryButton(
                onPressed: isSubmitting ? null : onContinue,
                icon: AppIcons.arrowForward,
                label: showAssessment
                    ? l10n.mixedEnterRecognition
                    : l10n.mixedAddLaterRecall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.item,
    required this.options,
    required this.checked,
    required this.lastCorrect,
    required this.lockedCorrect,
    required this.wrongTries,
    required this.onSelected,
  });

  final StudySessionQueueItem item;
  final List<String> options;
  final bool checked;
  final bool lastCorrect;
  final bool lockedCorrect;
  final Set<String> wrongTries;
  final ValueChanged<String> onSelected;

  /// Whether a non-review wrong answer is still open for re-selection.
  bool get _retryable => checked && !lastCorrect && !item.isReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _promptFor(l10n),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            AppPill(
              label: _stepLabelFor(l10n),
              icon: AppIcons.psychologyAlt,
            ),
            if (item.isReview)
              AppPill(
                label: l10n.mixedReviewQuickAnswer,
                icon: AppIcons.flashOn,
                variant: PillVariant.xp,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AppCard(
            child: ListView(
              children: [
                for (var i = 0; i < options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WordChoiceButton(
                      letter: String.fromCharCode(65 + i),
                      text: options[i],
                      state: _optionState(options[i]),
                      // Locked-correct or settled-review steps ignore taps; a
                      // non-review wrong answer stays tappable for re-select.
                      onTap: (lockedCorrect || (checked && !_retryable))
                          ? null
                          : () => onSelected(options[i]),
                    ),
                  ),
                if (checked) ...[
                  const SizedBox(height: 8),
                  Text(
                    lastCorrect
                        ? l10n.mixedFeedbackCorrect
                        : item.isReview
                        ? l10n.mixedFeedbackWrong
                        : l10n.mixedFeedbackRetry,
                    style: TextStyle(
                      color: lastCorrect
                          ? AppTokens.successColor(context)
                          : AppTokens.coralColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isCorrectOption(String option) {
    return option.trim().toLowerCase() == item.meaning.trim().toLowerCase();
  }

  ChoiceState _optionState(String option) {
    // Reveal the correct answer once the step is locked (correct) or a review
    // item has been answered; otherwise only mark tried-wrong options red.
    if ((lockedCorrect || (checked && item.isReview)) &&
        _isCorrectOption(option)) {
      return ChoiceState.correct;
    }
    if (wrongTries.contains(option)) return ChoiceState.wrong;
    return ChoiceState.idle;
  }

  String _promptFor(AppLocalizations l10n) {
    if (item.step == StudySessionStep.shortRecall) {
      return l10n.mixedShortRecallPrompt(item.displayWord);
    }
    if (item.step == StudySessionStep.recognition &&
        item.exampleSentence.isNotEmpty) {
      return item.exampleSentence;
    }
    return l10n.mixedMeaningPrompt(item.displayWord);
  }

  String _stepLabelFor(AppLocalizations l10n) {
    switch (item.step) {
      case StudySessionStep.recognition:
        return l10n.mixedStepRecognition;
      case StudySessionStep.shortRecall:
        return l10n.mixedStepShortRecall;
      case StudySessionStep.reviewRecall:
        return l10n.mixedStepDueReview;
      case StudySessionStep.understanding:
      case StudySessionStep.knowledgeCard:
        return l10n.mixedStepKnowledge;
    }
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.hasProgress,
    required this.onFinish,
    required this.isSubmitting,
  });

  final bool hasProgress;
  final VoidCallback onFinish;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MascotEmptyState(
      title: hasProgress ? l10n.mixedCompleteTitle : l10n.mixedNoContentTitle,
      message: hasProgress ? l10n.mixedCompleteBody : l10n.mixedNoContentBody,
      action: AppPrimaryButton(
        onPressed: isSubmitting ? null : onFinish,
        icon: AppIcons.home,
        label: l10n.mixedSaveAndHome,
      ),
    );
  }
}
