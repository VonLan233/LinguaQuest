import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/exercise_record.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quiz/lesson_result_screen.dart';
import 'passage_cloze_questions.dart';

class PassageClozeScreen extends ConsumerStatefulWidget {
  const PassageClozeScreen({super.key});

  @override
  ConsumerState<PassageClozeScreen> createState() => _PassageClozeScreenState();
}

class _PassageClozeScreenState extends ConsumerState<PassageClozeScreen> {
  static const _gameId = 'passage-cloze';
  late final DateTime _startedAt;
  List<QuizQuestion> _questions = const [];
  final Map<int, String> _selected = {};
  bool _isLoading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selected.clear();
    });
    final state = ref.read(appControllerProvider);
    final words = state.trainingWords;
    final seed = words.isNotEmpty ? words.first.word : 'study';
    final result = await ref.read(appControllerProvider.notifier).askAi(
          featureType: 'cloze',
          prompt: 'Write a SHORT passage (2-3 sentences) with 3-4 blanks using '
              'these words: ${words.take(6).map((w) => w.word).join(', ')}',
          targetWord: seed,
        );
    if (!mounted) return;
    final qs = passageClozeQuestions(result, words);
    setState(() {
      _isLoading = false;
      if (result.isEmpty) {
        _error = ref.read(appControllerProvider).errorMessage ??
            AppLocalizations.of(context).aiErrorGeneric;
      } else if (qs.isEmpty) {
        _error = AppLocalizations.of(context).aiErrorGeneric;
      } else {
        _questions = qs;
      }
    });
  }

  bool get _allAnswered => _selected.length >= _questions.length;

  Future<void> _finish() async {
    if (_questions.isEmpty) return;
    if (_submitting || !_allAnswered) return;
    setState(() => _submitting = true);
    final notifier = ref.read(appControllerProvider.notifier);
    final uid = ref.read(appControllerProvider).user?.uid ?? '';
    final now = DateTime.now();
    var correct = 0;
    final records = <ExerciseRecord>[];
    final mistakes = <QuizQuestion>[];
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final ans = _selected[i] ?? '';
      final ok = ans.trim().toLowerCase() == q.answer.trim().toLowerCase();
      if (ok) { correct++; } else { mistakes.add(q); }
      records.add(ExerciseRecord(
        id: 'exercise-${now.microsecondsSinceEpoch}-$i',
        uid: uid,
        sessionId: 'pending',
        gameId: _gameId,
        wordId: q.word.id,
        promptType: q.type.name,
        isCorrect: ok,
        answer: ans.trim(),
        correctAnswer: q.answer,
        answerTimeMs: 0,
        dimension: ReviewDimension.context,
        createdAt: now,
      ));
    }
    final accuracy = _questions.isEmpty ? 0.0 : correct / _questions.length;
    final xp = (correct * 5 + (accuracy * 10).round()).clamp(0, 80).toInt();
    final result = LessonResult(
      lessonId: _gameId,
      lessonTitle: AppLocalizations.of(context).trainingPassageCloze,
      totalQuestions: _questions.length,
      correctAnswers: correct,
      xpEarned: xp,
      mistakes: List.unmodifiable(mistakes),
      completedAt: now,
    );
    final ok = await notifier.completeTraining(
      result: result,
      gameId: _gameId,
      startedAt: _startedAt,
      exerciseRecords: List.unmodifiable(records),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _submitting = false);
      return;
    }
    context.go('/lesson/$_gameId/result',
        extra: LessonResultViewArgs(
            result: result, source: LessonResultSource.training));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingPassageCloze),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/training')),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI is writing a short passage… (about 10–20s)',
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            : _error != null
                ? ListView(padding: const EdgeInsets.all(20), children: [
                    AiErrorCard(message: _error!, onRetry: _load),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    children: [
                      for (var i = 0; i < _questions.length; i++)
                        _BlankCard(
                          index: i,
                          question: _questions[i],
                          selected: _selected[i],
                          onSelect: (opt) =>
                              setState(() => _selected[i] = opt),
                        ),
                    ],
                  ),
      ),
      bottomNavigationBar: (_isLoading || _error != null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: AppPrimaryButton(
                  label: _submitting
                      ? 'Submitting...'
                      : _allAnswered
                          ? 'Finish'
                          : 'Answer all blanks',
                  onPressed: (_allAnswered && !_submitting) ? _finish : null,
                ),
              ),
            ),
    );
  }
}

class _BlankCard extends StatelessWidget {
  const _BlankCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final QuizQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: AppCard(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.prompt, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppTokens.s12),
            for (var o = 0; o < question.options.length; o++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: WordChoiceButton(
                  letter: o < _letters.length ? _letters[o] : '${o + 1}',
                  text: question.options[o],
                  state: selected == null
                      ? ChoiceState.idle
                      : question.options[o] == selected
                          ? (selected == question.answer
                              ? ChoiceState.correct
                              : ChoiceState.wrong)
                          : (question.options[o] == question.answer
                              ? ChoiceState.correct
                              : ChoiceState.idle),
                  onTap: selected == null
                      ? () => onSelect(question.options[o])
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
