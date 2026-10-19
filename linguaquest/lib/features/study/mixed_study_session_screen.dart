import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/services/answer_sound_service.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/study_session_draft.dart';
import '../../l10n/generated/app_localizations.dart';
import 'session/recognition_prompt.dart';
import 'session/session_queue_builder.dart';

class MixedStudySessionScreen extends ConsumerStatefulWidget {
  const MixedStudySessionScreen({required this.mode, super.key});

  final StudySessionEntryMode mode;

  @override
  ConsumerState<MixedStudySessionScreen> createState() =>
      _MixedStudySessionScreenState();
}

class _MixedStudySessionScreenState
    extends ConsumerState<MixedStudySessionScreen> {
  static const _builder = StudySessionQueueBuilder();

  final Random _random = Random();
  final List<StudySessionQueueItem> _queue = [];
  final List<StudyAnswerLog> _answerLogs = [];
  final Set<String> _wrongItemIds = {};
  final Set<String> _scheduledWrongIds = {};
  final Set<String> _wrongTries = {};
  late DateTime _sessionStartedAt;
  DateTime _itemStartedAt = DateTime.now();
  StudySessionQueuePlan? _plan;
  bool _allowExit = false;
  bool _checked = false;
  bool _lastCorrect = false;
  bool _lockedCorrect = false;
  bool _isSubmitting = false;
  bool _reviewSaveFailed = false;
  int _completedItems = 0;
  int _correctAnswers = 0;
  int _confidence = 3;
  List<String> _currentOptions = const [];

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeQueue());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final learningLanguage = ref.watch(
      appControllerProvider.select((s) => s.currentLanguage),
    );
    final current = _queue.isEmpty ? null : _queue.first;
    final total = _completedItems + _queue.length;
    final progress = total == 0
        ? 1.0
        : (_completedItems / total).clamp(0.0, 1.0).toDouble();

    return PopScope(
      canPop: _allowExit || (!_hasProgress && !_isSubmitting),
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
                            child: AppProgressBar(
                              value: progress,
                              height: 6,
                              solid: true,
                              solidColor: Theme.of(context).colorScheme.primary,
                            ),
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
                                language: learningLanguage,
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
                                key: ValueKey('${current.id}:$_completedItems'),
                                item: current,
                                language: learningLanguage,
                                saveFailed: _reviewSaveFailed,
                                onRetrySave: () {
                                  final last = _answerLogs.last;
                                  _persistReviewAttempt(
                                    current,
                                    _lastCorrect,
                                    last.responseTimeMs,
                                    last.selectedAnswer,
                                  );
                                },
                                isSubmitting: _isSubmitting,
                                onNext: _advanceCurrent,
                                localeCode: Localizations.localeOf(
                                  context,
                                ).languageCode,
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

  Future<void> _initializeQueue() async {
    final state = ref.read(appControllerProvider);
    if (await _restoreDraft(state)) return;
    final dailyGoal = state.dailyNewTarget;
    final newWords = state.availableNewWords;
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

  Future<bool> _restoreDraft(AppState state) async {
    final uid = state.user?.uid;
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = _draftKey(uid);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return false;
    try {
      final draft = StudySessionDraft.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (!_canRestoreDraft(draft, state, uid)) {
        await prefs.remove(key);
        return false;
      }
      if (!mounted) return true;
      final firstItem = draft.queue.first;
      final options = _buildOptionsFor(firstItem, state);
      setState(() {
        _sessionStartedAt = draft.startedAt;
        _plan = draft.plan;
        _queue
          ..clear()
          ..addAll(draft.queue);
        _answerLogs
          ..clear()
          ..addAll(draft.answerLogs);
        _wrongItemIds
          ..clear()
          ..addAll(draft.wrongItemIds);
        _scheduledWrongIds
          ..clear()
          ..addAll(draft.scheduledWrongIds);
        _completedItems = draft.completedItems;
        _correctAnswers = draft.correctAnswers;
        _confidence = draft.confidence;
        _currentOptions = options;
        _itemStartedAt = DateTime.now();
      });
      return true;
    } catch (_) {
      await prefs.remove(key);
      return false;
    }
  }

  bool _canRestoreDraft(StudySessionDraft draft, AppState state, String uid) {
    if (draft.uid != uid || draft.mode != widget.mode || draft.queue.isEmpty) {
      return false;
    }
    final currentLesson = state.currentLesson;
    if (draft.lessonId != (currentLesson?.id ?? '')) return false;
    // New words are drawn from the whole current wordbook (see availableNewWords),
    // not just the 3-word currentLesson, so validate a restored draft's new-word
    // items against the wordbook pool.
    final newWordIds = {
      for (final word in state.currentWordBook?.words ?? const <Word>[])
        word.id,
    };
    final customWordIds = {for (final word in state.customWords) word.id};
    for (final item in draft.queue) {
      if (item.isNewWord && !newWordIds.contains(item.wordId)) {
        return false;
      }
      if (!item.isNewWord && !customWordIds.contains(item.wordId)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _continueFromCard(StudySessionQueueItem item) async {
    if (_isSubmitting) return;
    if (item.step == StudySessionStep.understanding) {
      _applySelfAssessment(item);
    }
    _advanceCurrent();
  }

  /// Confirmed answers persist once; feedback remains until the learner continues.
  Future<void> _judgeQuestion(StudySessionQueueItem item, String answer) async {
    // Ignore taps while a settle/persist is in flight, or once a correct (or
    // settled review) answer has locked the step.
    if (_isSubmitting || _lockedCorrect || (_checked && item.isReview)) return;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isCorrect =
        answer.trim().toLowerCase() ==
        item.meaningFor(localeCode).trim().toLowerCase();
    unawaited(
      AnswerSoundService.play(
        isCorrect: isCorrect,
        enabled: ref.read(appControllerProvider).sensorySettings.soundEnabled,
      ),
    );
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
  }

  Future<void> _persistReviewAttempt(
    StudySessionQueueItem item,
    bool isCorrect,
    int responseTime,
    String answer,
  ) async {
    setState(() {
      _isSubmitting = true;
      _reviewSaveFailed = false;
    });
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
        setState(() => _reviewSaveFailed = true);
        _showSubmitError(AppLocalizations.of(context).mixedSaveReviewFailed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _reviewSaveFailed = true);
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
    if (_isSubmitting || _reviewSaveFailed) return;
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
    final localeCode = Localizations.localeOf(context).languageCode;
    final answer = item.meaningFor(localeCode);
    final answerKey = answer.trim().toLowerCase();
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
        if (word.id != item.wordId) {
          addDistractor(word.primaryDefinitionFor(localeCode));
        }
      }
    }
    for (final word in state.customWords) {
      if (word.id != item.wordId) {
        addDistractor(customWordMeaningFor(word, localeCode));
      }
    }

    final options = <String>[answer];
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
        content: Text(dialogL10n.practiceExitHint),
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
      final saved = await _saveDraft();
      if (!activeContext.mounted || !saved) return;
    } else if (action == _ExitAction.discard) {
      await _clearDraft();
      if (!activeContext.mounted) return;
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
    if (saved) {
      await _clearDraft();
      if (!mounted) return;
      context.go('/home');
    }
  }

  Future<bool> _saveDraft() async {
    final state = ref.read(appControllerProvider);
    final uid = state.user?.uid;
    if (uid == null || _isSubmitting) return false;
    setState(() => _isSubmitting = true);
    try {
      final draft = StudySessionDraft(
        uid: uid,
        mode: widget.mode,
        lessonId: state.currentLesson?.id ?? '',
        startedAt: _sessionStartedAt,
        savedAt: DateTime.now(),
        completedItems: _completedItems,
        correctAnswers: _correctAnswers,
        confidence: _confidence,
        reviewTargetRatio: _plan?.reviewTargetRatio ?? 0,
        newTargetRatio: _plan?.newTargetRatio ?? 0,
        dueReviewCount: _plan?.dueReviewCount ?? 0,
        newWordCount: _plan?.newWordCount ?? 0,
        weakWordCount: _plan?.weakWordCount ?? 0,
        queue: List.unmodifiable(_queue),
        answerLogs: List.unmodifiable(_answerLogs),
        wrongItemIds: Set.unmodifiable(_wrongItemIds),
        scheduledWrongIds: Set.unmodifiable(_scheduledWrongIds),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey(uid), jsonEncode(draft.toJson()));
      return true;
    } catch (_) {
      if (mounted) {
        _showSubmitError(AppLocalizations.of(context).mixedSaveStudyFailed);
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _clearDraft() async {
    final uid = ref.read(appControllerProvider).user?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(uid));
  }

  String _draftKey(String uid) {
    return 'linguaquest.study_session_draft.$uid.${widget.mode.name}';
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

  Future<void> _leave(BuildContext activeContext) async {
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!activeContext.mounted) return;
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
    required this.language,
    required this.showAssessment,
    required this.selectedConfidence,
    required this.isSubmitting,
    required this.onConfidenceChanged,
    required this.onContinue,
  });

  final StudySessionQueueItem item;
  final String language;
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
              Center(
                child: PronunciationControls(
                  word: item.displayWord,
                  compact: true,
                  language: language,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.meaningFor(Localizations.localeOf(context).languageCode),
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
                    selectedBackgroundColor: theme.colorScheme.primaryContainer,
                    selectedForegroundColor:
                        theme.colorScheme.onPrimaryContainer,
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

class _QuestionStep extends StatefulWidget {
  const _QuestionStep({
    super.key,
    required this.item,
    required this.language,
    required this.saveFailed,
    required this.onRetrySave,
    required this.options,
    required this.checked,
    required this.lastCorrect,
    required this.lockedCorrect,
    required this.wrongTries,
    required this.onSelected,
    required this.localeCode,
    required this.onNext,
    required this.isSubmitting,
  });
  final StudySessionQueueItem item;
  final String localeCode, language;
  final bool saveFailed;
  final VoidCallback onRetrySave;
  final List<String> options;
  final bool checked, lastCorrect, lockedCorrect, isSubmitting;
  final Set<String> wrongTries;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;
  @override
  State<_QuestionStep> createState() => _QuestionStepState();
}

class _QuestionStepState extends State<_QuestionStep> {
  String? _selected;
  bool get _settled =>
      widget.lockedCorrect || (widget.checked && widget.item.isReview);
  bool _correct(String option) =>
      option.trim().toLowerCase() ==
      widget.item.meaningFor(widget.localeCode).trim().toLowerCase();
  ChoiceState _choiceState(String option) {
    if (_settled && _correct(option)) return ChoiceState.correct;
    if (widget.wrongTries.contains(option)) return ChoiceState.wrong;
    return _selected == option ? ChoiceState.selected : ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final item = widget.item;
    final feedback =
        widget.checked &&
        (_settled ||
            _selected == null ||
            widget.wrongTries.contains(_selected));
    final accent = widget.lastCorrect
        ? AppTokens.successColor(context)
        : AppTokens.dangerColor(context);
    final phonetic = item.lessonWord?.phoneticFor(widget.language) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.practiceChooseMeaning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.displayWord,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: feedback ? 28 : 38,
                ),
              ),
              Center(
                child: PronunciationControls(
                  word: item.displayWord,
                  compact: true,
                  language: widget.language,
                ),
              ),
              if (phonetic.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  phonetic,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (item.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      for (final segment in recognitionPromptSegments(
                        item.exampleSentence,
                        item.displayWord,
                      ))
                        TextSpan(
                          text: segment.text,
                          style: segment.highlight
                              ? TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                )
                              : null,
                        ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              for (var i = 0; i < widget.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WordChoiceButton(
                    letter: String.fromCharCode(65 + i),
                    text: widget.options[i],
                    state: _choiceState(widget.options[i]),
                    onTap: _settled || widget.isSubmitting
                        ? null
                        : () => setState(() => _selected = widget.options[i]),
                  ),
                ),
            ],
          ),
        ),
        if (feedback)
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.lastCorrect
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.lastCorrect
                              ? l10n.practiceCorrect
                              : item.isReview
                              ? l10n.practiceReviewAnswer
                              : l10n.mixedFeedbackRetry,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_settled) ...[
                    const SizedBox(height: 8),
                    Text(item.meaningFor(widget.localeCode)),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        AppPrimaryButton(
          label: widget.saveFailed
              ? l10n.commonRetry
              : _settled
              ? l10n.practiceNext
              : l10n.practiceCheck,
          icon: _settled ? Icons.arrow_forward_rounded : Icons.check_rounded,
          onPressed: widget.isSubmitting
              ? null
              : _settled
              ? widget.saveFailed
                    ? widget.onRetrySave
                    : widget.onNext
              : _selected == null || widget.wrongTries.contains(_selected)
              ? null
              : () => widget.onSelected(_selected!),
        ),
        const SizedBox(height: 4),
      ],
    );
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
