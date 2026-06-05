import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
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
  late final DateTime _sessionStartedAt;
  DateTime _itemStartedAt = DateTime.now();
  StudySessionQueuePlan? _plan;
  String? _selected;
  bool _checked = false;
  bool _lastCorrect = false;
  bool _isSubmitting = false;
  int _completedItems = 0;
  int _correctAnswers = 0;
  int _confidence = 3;
  List<String>? _cachedOptions;
  String? _cachedOptionsItemId;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeQueue());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
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
          title: Text(_title),
          actions: [
            if (widget.mode == StudySessionEntryMode.reviewOnly)
              TextButton(
                onPressed: _isSubmitting ? null : () => context.push('/review'),
                child: const Text('管理复习队列'),
              ),
            if (_plan != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: PillLabel(
                    label: '复习 ${(_plan!.reviewTargetRatio * 100).round()}%',
                    icon: Icons.shuffle_rounded,
                    color: AppTheme.cyan,
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 11,
                                backgroundColor: AppTheme.progressTrack(
                                  context,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PillLabel(
                            label: '${_completedItems + 1}/$total',
                            icon: Icons.auto_awesome_motion_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: current.step == StudySessionStep.understanding ||
                                current.isKnowledgeCard
                            ? _KnowledgeCardStep(
                                item: current,
                                showAssessment: current.step ==
                                    StudySessionStep.understanding,
                                selectedConfidence: _confidence,
                                isSubmitting: _isSubmitting,
                                onConfidenceChanged: (value) =>
                                    setState(() => _confidence = value),
                                onContinue: () => _continueFromCard(current),
                              )
                            : _QuestionStep(
                                item: current,
                                options: _optionsFor(current, state),
                                selected: _selected,
                                checked: _checked,
                                lastCorrect: _lastCorrect,
                                isSubmitting: _isSubmitting,
                                onSelected: (value) =>
                                    setState(() => _selected = value),
                                onPrimary: () =>
                                    _handleQuestionPrimary(current),
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String get _title {
    switch (widget.mode) {
      case StudySessionEntryMode.newOnly:
        return '今日新学包';
      case StudySessionEntryMode.reviewOnly:
        return '快速复习';
      case StudySessionEntryMode.mixed:
        return '今日混排学习包';
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
    setState(() {
      _plan = plan;
      _queue
        ..clear()
        ..addAll(plan.items);
      _cachedOptions = null;
      _cachedOptionsItemId = null;
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

  Future<void> _handleQuestionPrimary(StudySessionQueueItem item) async {
    if (_isSubmitting) return;
    if (!_checked) {
      final answer = _selected;
      if (answer == null) return;
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
      });
      if (item.isReview && item.affectsSchedule) {
        await _persistReviewAttempt(item, isCorrect, responseTime, answer);
      }
      return;
    }

    if (!_lastCorrect && !item.isReview) {
      setState(() {
        _checked = false;
        _selected = null;
        _itemStartedAt = DateTime.now();
      });
      return;
    }

    if (_lastCorrect && !_wrongItemIds.contains(item.wordId)) {
      _correctAnswers += 1;
    }
    _advanceCurrent();
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
        _showSubmitError('暂时无法保存复习记录');
      }
    } catch (_) {
      if (mounted) _showSubmitError('暂时无法保存复习记录');
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
    setState(() {
      if (_queue.isNotEmpty) _queue.removeAt(0);
      _completedItems += 1;
      _selected = null;
      _checked = false;
      _lastCorrect = false;
      _confidence = 3;
      _cachedOptions = null;
      _cachedOptionsItemId = null;
      _itemStartedAt = DateTime.now();
    });
  }

  List<String> _optionsFor(StudySessionQueueItem item, AppState state) {
    if (_cachedOptionsItemId == item.id && _cachedOptions != null) {
      return _cachedOptions!;
    }

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
      options.add('还不确定 ${options.length}');
    }
    options.shuffle(_random);
    _cachedOptions = List.unmodifiable(options);
    _cachedOptionsItemId = item.id;
    return _cachedOptions!;
  }

  Future<void> _handleExit(BuildContext activeContext) async {
    if (!_hasProgress) {
      _leave(activeContext);
      return;
    }
    final action = await showDialog<_ExitAction>(
      context: activeContext,
      builder: (context) => AlertDialog(
        title: const Text('保存本次进度？'),
        content: const Text('已保存的复习记录会保留；保存后会记录本次已完成题目，未完成词下次仍会进入学习包。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitAction.continueStudy),
            child: const Text('继续学习'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitAction.discard),
            child: const Text('不保存离开'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _ExitAction.save),
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存并离开'),
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
        _showSubmitError('暂时无法保存学习进度');
      }
      return succeeded;
    } catch (_) {
      if (mounted) _showSubmitError('暂时无法保存学习进度');
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
    return ListView(
      children: [
        ImageCueBadge(cue: item.imageCue, size: 92),
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
          Text('先自评，系统会调整今天的重复次数', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('认识')),
              ButtonSegment(value: 3, label: Text('模糊')),
              ButtonSegment(value: 1, label: Text('不认识')),
            ],
            selected: {selectedConfidence},
            onSelectionChanged: (values) => onConfidenceChanged(values.first),
          ),
          const SizedBox(height: 20),
        ],
        FilledButton.icon(
          onPressed: isSubmitting ? null : onContinue,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(showAssessment ? '进入识别题' : '加入稍后复现'),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.item,
    required this.options,
    required this.selected,
    required this.checked,
    required this.lastCorrect,
    required this.isSubmitting,
    required this.onSelected,
    required this.onPrimary,
  });

  final StudySessionQueueItem item;
  final List<String> options;
  final String? selected;
  final bool checked;
  final bool lastCorrect;
  final bool isSubmitting;
  final ValueChanged<String> onSelected;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _prompt,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            PillLabel(label: _stepLabel, icon: Icons.psychology_alt_outlined),
            if (item.isReview)
              const PillLabel(label: '复习快答', icon: Icons.flash_on_outlined),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton(
                      onPressed: checked ? null : () => onSelected(option),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: _optionBackground(context, option),
                        foregroundColor: _optionForeground(context, option),
                        side: BorderSide(
                          color: _optionBorder(context, option),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              if (checked) ...[
                const SizedBox(height: 8),
                Text(
                  lastCorrect
                      ? '答对了，继续下一题。'
                      : item.isReview
                      ? '答错了，先看知识卡，稍后会再次出现。'
                      : '还不对。请选择到正确答案后再进入下一题。',
                  style: TextStyle(
                    color: lastCorrect
                        ? AppTheme.success
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: selected == null || isSubmitting ? null : onPrimary,
          icon: Icon(
            checked ? Icons.arrow_forward_rounded : Icons.check_rounded,
          ),
          label: Text(
            checked ? (lastCorrect || item.isReview ? '继续' : '再试一次') : '检查',
          ),
        ),
      ],
    );
  }

  String get _prompt {
    if (item.step == StudySessionStep.shortRecall) {
      return '短间隔回忆：${item.displayWord} 的意思是？';
    }
    if (item.step == StudySessionStep.recognition &&
        item.exampleSentence.isNotEmpty) {
      return item.exampleSentence;
    }
    return '${item.displayWord} 的中文释义是？';
  }

  String get _stepLabel {
    switch (item.step) {
      case StudySessionStep.recognition:
        return '识别';
      case StudySessionStep.shortRecall:
        return '短间隔回忆';
      case StudySessionStep.reviewRecall:
        return '到期复习';
      case StudySessionStep.understanding:
      case StudySessionStep.knowledgeCard:
        return '知识卡';
    }
  }

  Color _optionBackground(BuildContext context, String option) {
    if (!checked) {
      return selected == option
          ? AppTheme.selectedSurface(context)
          : Theme.of(context).colorScheme.surface;
    }
    if (option == item.meaning) return AppTheme.success.withValues(alpha: 0.12);
    if (option == selected) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.12);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _optionForeground(BuildContext context, String option) {
    if (!checked) return Theme.of(context).colorScheme.onSurface;
    if (option == item.meaning) return AppTheme.success;
    if (option == selected) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.onSurface;
  }

  Color _optionBorder(BuildContext context, String option) {
    if (!checked) {
      return selected == option
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outlineVariant;
    }
    if (option == item.meaning) return AppTheme.success;
    if (option == selected) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.outlineVariant;
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
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: hasProgress ? '今日学习包完成' : '今日没有待学习内容',
      message: hasProgress ? '错题已经在本轮回收，答题记录和用时会保存到学习日志。' : '当前没有新词或到期复习词。',
      action: FilledButton.icon(
        onPressed: isSubmitting ? null : onFinish,
        icon: const Icon(Icons.home_outlined),
        label: const Text('保存并回首页'),
      ),
    );
  }
}
