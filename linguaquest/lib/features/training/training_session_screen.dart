import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/exercise_record.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../quiz/lesson_result_screen.dart';

enum TrainingGameType {
  wordRush('word-rush', '抢词', Icons.timer_outlined),
  survival('survival', '一站到底', Icons.stairs_outlined),
  spelling('spelling', '单词拼写', Icons.edit_note_outlined);

  const TrainingGameType(this.id, this.title, this.icon);

  final String id;
  final String title;
  final IconData icon;

  static TrainingGameType? fromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

class TrainingSessionScreen extends ConsumerStatefulWidget {
  const TrainingSessionScreen({
    required this.gameId,
    this.mistakesOnly = false,
    super.key,
  });

  final String gameId;
  final bool mistakesOnly;

  @override
  ConsumerState<TrainingSessionScreen> createState() =>
      _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  static const _rushSeconds = 60;
  static const _feedbackDuration = Duration(milliseconds: 520);
  static const _spellingQuestionCount = 9;
  static const _survivalQuestionCount = 18;

  final _textController = TextEditingController();
  final List<QuizQuestion> _questions = [];
  final List<QuizQuestion> _mistakes = [];
  final List<ExerciseRecord> _records = [];
  final Set<String> _mistakeQuestionIds = {};
  late final DateTime _startedAt;
  Timer? _timer;
  TrainingGameType? _game;
  bool _initialized = false;
  bool _checked = false;
  bool _lastCorrect = false;
  bool _usedReviveForLastMistake = false;
  bool _isSubmitting = false;
  String? _selected;
  int _index = 0;
  int _attempts = 0;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _remainingSeconds = _rushSeconds;
  int _revives = 1;
  int _nodeRewards = 0;
  DateTime _questionStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _questionStartedAt = _startedAt;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final game = _game ?? TrainingGameType.fromId(widget.gameId);
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练入口不存在')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: '没有找到这个训练',
                subtitle: '请回到训练场，从抢词、一站到底或单词拼写入口开始。',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/training'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('返回训练场'),
              ),
            ],
          ),
        ),
      );
    }
    _ensureQuestions(state, game);
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(game.title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: '训练题源不足',
                subtitle: '先完成一节新学、添加生词，或在错词本里积累弱项词后再来挑战。',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/training'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('返回训练场'),
              ),
            ],
          ),
        ),
      );
    }
    final question = _questions[_index % _questions.length];
    final progress = _progressFor(game);
    final accuracy = _attempts == 0 ? 0 : (_correct / _attempts * 100).round();

    return PopScope(
      canPop: _attempts == 0 && !_checked && !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _confirmExit),
          title: Text(widget.mistakesOnly ? '错词再练' : game.title),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrainingStatusLine(
                  game: game,
                  progress: progress,
                  remainingSeconds: _remainingSeconds,
                  correct: _correct,
                  attempts: _attempts,
                  streak: _streak,
                  bestStreak: _bestStreak,
                  revives: _revives,
                  nodeRewards: _nodeRewards,
                  accuracy: accuracy,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TrainingPromptPanel(
                          game: game,
                          question: question,
                          mistakesOnly: widget.mistakesOnly,
                        ),
                        const SizedBox(height: 18),
                        if (game == TrainingGameType.spelling)
                          _SpellingInput(
                            controller: _textController,
                            checked: _checked,
                            isCorrect: _lastCorrect,
                            onChanged: () => setState(() {}),
                          )
                        else
                          _ChoiceInput(
                            question: question,
                            selected: _selected,
                            checked: _checked,
                            onSelected: _submitAnswer,
                          ),
                        if (_checked) ...[
                          const SizedBox(height: 14),
                          _TrainingFeedback(
                            isCorrect: _lastCorrect,
                            question: question,
                            game: game,
                            revives: _revives,
                            reviveConsumed: _usedReviveForLastMistake,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (game == TrainingGameType.spelling)
                  FilledButton.icon(
                    onPressed: _canSubmitSpelling
                        ? () => _submitAnswer(_textController.text.trim())
                        : null,
                    icon: Icon(
                      _checked
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                    ),
                    label: Text(_checked ? '下一题' : '提交拼写'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSubmitSpelling {
    if (_isSubmitting) return false;
    if (_checked) return true;
    return _textController.text.trim().isNotEmpty;
  }

  Future<void> _confirmExit() async {
    if (_attempts > 0 || _checked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('离开训练？'),
          content: const Text('当前训练进度不会结算。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续训练'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('离开'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    context.go('/training');
  }

  void _ensureQuestions(AppState state, TrainingGameType game) {
    if (_initialized && _game == game) return;
    _game = game;
    final words = _sourceWordsForGame(state, game);
    var distinctWords = _distinctWords(words);
    final minimumWords = game == TrainingGameType.spelling ? 1 : 3;
    if (!widget.mistakesOnly && distinctWords.length < minimumWords) {
      distinctWords = _distinctWords(state.trainingWords);
    }
    if (distinctWords.length < minimumWords) {
      _initialized = true;
      return;
    }
    _questions
      ..clear()
      ..addAll(_buildQuestions(game, distinctWords));
    _initialized = true;
    _questionStartedAt = DateTime.now();
    if (game == TrainingGameType.wordRush) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _isSubmitting) return;
        if (_remainingSeconds <= 1) {
          _timer?.cancel();
          _finishTraining();
          return;
        }
        setState(() => _remainingSeconds--);
      });
    }
  }

  List<Word> _mistakeWords(AppState state) {
    final mistakes = state.lastResult?.mistakes ?? const <QuizQuestion>[];
    if (mistakes.isEmpty) return state.weakWords.map(_wordFromCustom).toList();
    return mistakes.map((question) => question.word).toList();
  }

  List<Word> _sourceWordsForGame(AppState state, TrainingGameType game) {
    if (widget.mistakesOnly) return _mistakeWords(state);
    final weakWords = state.weakWords.map(_wordFromCustom).toList();
    final dueWords = state.dueWords.map(_wordFromCustom).toList();
    final learnedWords = state.formalLessons
        .where((lesson) => state.completedLessonIds.contains(lesson.id))
        .expand((lesson) => lesson.words)
        .toList();
    final currentBookWords = state.formalLessons
        .expand((lesson) => lesson.words)
        .toList(growable: false);
    final spellingWeakWords = [...state.weakWords]
      ..sort((a, b) => a.spellingScore.compareTo(b.spellingScore));

    final source = switch (game) {
      TrainingGameType.wordRush => [...learnedWords, ...dueWords],
      TrainingGameType.survival => [...currentBookWords, ...weakWords],
      TrainingGameType.spelling =>
        spellingWeakWords.map(_wordFromCustom).toList(),
    };
    return source.isEmpty ? state.trainingWords : source;
  }

  List<Word> _distinctWords(Iterable<Word> words) {
    final merged = <String, Word>{};
    for (final word in words) {
      final key = word.word.trim().toLowerCase();
      if (key.isEmpty) continue;
      merged.putIfAbsent(key, () => word);
    }
    return merged.values.toList(growable: false);
  }

  List<QuizQuestion> _buildQuestions(TrainingGameType game, List<Word> words) {
    final count = switch (game) {
      TrainingGameType.wordRush => words.length * 4,
      TrainingGameType.survival => _survivalQuestionCount,
      TrainingGameType.spelling => _spellingQuestionCount,
    };
    return [
      for (var index = 0; index < count; index++)
        _questionFor(game, words[index % words.length], words, index),
    ];
  }

  QuizQuestion _questionFor(
    TrainingGameType game,
    Word word,
    List<Word> words,
    int index,
  ) {
    switch (game) {
      case TrainingGameType.wordRush:
        return QuizQuestion(
          id: '${game.id}-${word.id}-$index',
          type: QuizQuestionType.meaningChoice,
          prompt: '抢答“${word.word}”的中文释义',
          answer: word.meaning,
          options: _options(
            answer: word.meaning,
            values: words.map((item) => item.meaning),
            offset: index,
          ),
          explanation:
              '“${word.word}”表示${word.meaning}。${word.exampleSentence}',
          word: word,
        );
      case TrainingGameType.survival:
        final variant = index % 3;
        if (variant == 1) {
          return QuizQuestion(
            id: '${game.id}-${word.id}-$index',
            type: QuizQuestionType.chineseChoice,
            prompt: '根据中文释义选择英文：${word.meaning}',
            answer: word.word,
            options: _options(
              answer: word.word,
              values: words.map((item) => item.word),
              offset: index,
            ),
            explanation: '${word.meaning} 对应 “${word.word}”。',
            word: word,
          );
        }
        return QuizQuestion(
          id: '${game.id}-${word.id}-$index',
          type: variant == 2
              ? QuizQuestionType.contextChoice
              : QuizQuestionType.meaningChoice,
          prompt: variant == 2
              ? '结合例句选择释义：${word.exampleSentence}'
              : '选择“${word.word}”的中文释义',
          answer: word.meaning,
          options: _options(
            answer: word.meaning,
            values: words.map((item) => item.meaning),
            offset: index,
          ),
          explanation: '这题考察 ${word.word}：${word.meaning}。',
          word: word,
        );
      case TrainingGameType.spelling:
        final variant = index % 3;
        final prompt = switch (variant) {
          0 => '看中文拼写英文：${word.meaning}',
          1 => '听音后拼写英文：${word.phonetic.isEmpty ? word.word : word.phonetic}',
          _ => '根据例句空格拼写：${_blankExample(word)}',
        };
        return QuizQuestion(
          id: '${game.id}-${word.id}-$index',
          type: QuizQuestionType.spelling,
          prompt: prompt,
          answer: word.word,
          options: const [],
          explanation: '正确拼写是 “${word.word}”。${word.exampleSentence}',
          word: word,
        );
    }
  }

  List<String> _options({
    required String answer,
    required Iterable<String> values,
    required int offset,
  }) {
    final cleanValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final options = <String>[];
    final seen = <String>{};
    void add(String value) {
      final key = value.toLowerCase();
      if (seen.add(key)) options.add(value);
    }

    add(answer);
    for (
      var step = 0;
      step < cleanValues.length && options.length < 4;
      step++
    ) {
      add(cleanValues[(offset + step + 1) % cleanValues.length]);
    }
    return List.unmodifiable(options);
  }

  String _blankExample(Word word) {
    final expression = RegExp(RegExp.escape(word.word), caseSensitive: false);
    final sentence = word.exampleSentence.trim();
    if (sentence.isEmpty) return '____ (${word.meaning})';
    return sentence.replaceFirst(expression, '____');
  }

  void _submitAnswer(String answer) {
    final game = _game ?? TrainingGameType.fromId(widget.gameId);
    if (game == null) return;
    if (_isSubmitting || _questions.isEmpty) return;
    if (_checked && game == TrainingGameType.spelling) {
      _advanceAfterFeedback(game);
      return;
    }
    if (_checked) return;

    final question = _questions[_index % _questions.length];
    final normalizedAnswer = answer.trim().toLowerCase();
    final isCorrect = normalizedAnswer == question.answer.trim().toLowerCase();
    final answeredAt = DateTime.now();
    final nextStreak = isCorrect ? _streak + 1 : 0;
    final consumedRevive =
        game == TrainingGameType.survival && !isCorrect && _revives > 0;
    final earnedNodeReward =
        game == TrainingGameType.survival &&
        isCorrect &&
        (_correct + 1) % 5 == 0;

    setState(() {
      _checked = true;
      _lastCorrect = isCorrect;
      _usedReviveForLastMistake = consumedRevive;
      _selected = answer;
      _attempts++;
      if (isCorrect) {
        _correct++;
        _streak = nextStreak;
        if (_streak > _bestStreak) _bestStreak = _streak;
        if (earnedNodeReward) _nodeRewards++;
      } else {
        _streak = 0;
        if (_mistakeQuestionIds.add(question.id)) _mistakes.add(question);
        if (consumedRevive) _revives--;
      }
      _records.add(
        ExerciseRecord(
          id: 'exercise-${answeredAt.microsecondsSinceEpoch}-${_records.length}',
          uid: ref.read(appControllerProvider).user?.uid ?? '',
          sessionId: 'pending',
          gameId: game.id,
          wordId: question.word.id,
          promptType: _promptType(question, game),
          isCorrect: isCorrect,
          answer: answer.trim(),
          correctAnswer: question.answer,
          answerTimeMs: answeredAt
              .difference(_questionStartedAt)
              .inMilliseconds,
          dimension: _dimensionFor(question, game),
          createdAt: answeredAt,
        ),
      );
    });

    if (game == TrainingGameType.wordRush ||
        game == TrainingGameType.survival) {
      Future<void>.delayed(_feedbackDuration, () {
        if (!mounted || _isSubmitting) return;
        if (game == TrainingGameType.survival &&
            !isCorrect &&
            !consumedRevive) {
          _finishTraining();
          return;
        }
        _advanceAfterFeedback(game);
      });
    }
  }

  void _advanceAfterFeedback(TrainingGameType game) {
    if (_isSubmitting) return;
    final shouldFinish = switch (game) {
      TrainingGameType.wordRush => _remainingSeconds <= 0,
      TrainingGameType.survival => _index >= _questions.length - 1,
      TrainingGameType.spelling => _index >= _questions.length - 1,
    };
    if (shouldFinish) {
      _finishTraining();
      return;
    }
    setState(() {
      _index++;
      _checked = false;
      _lastCorrect = false;
      _usedReviveForLastMistake = false;
      _selected = null;
      _textController.clear();
      _questionStartedAt = DateTime.now();
    });
  }

  double _progressFor(TrainingGameType game) {
    switch (game) {
      case TrainingGameType.wordRush:
        return ((_rushSeconds - _remainingSeconds) / _rushSeconds).clamp(
          0.0,
          1.0,
        );
      case TrainingGameType.survival:
      case TrainingGameType.spelling:
        return ((_index + 1) / _questions.length).clamp(0.0, 1.0);
    }
  }

  String _promptType(QuizQuestion question, TrainingGameType game) {
    if (game != TrainingGameType.spelling) return question.type.name;
    final idParts = question.id.split('-');
    final rawIndex = int.tryParse(idParts.last) ?? 0;
    return switch (rawIndex % 3) {
      0 => 'chinese-spelling',
      1 => 'audio-spelling',
      _ => 'context-spelling',
    };
  }

  ReviewDimension _dimensionFor(QuizQuestion question, TrainingGameType game) {
    if (game == TrainingGameType.spelling) {
      return _promptType(question, game) == 'audio-spelling'
          ? ReviewDimension.listening
          : ReviewDimension.spelling;
    }
    return switch (question.type) {
      QuizQuestionType.chineseChoice => ReviewDimension.meaningRecall,
      QuizQuestionType.contextChoice => ReviewDimension.context,
      _ => ReviewDimension.meaningRecognition,
    };
  }

  int _xpFor(TrainingGameType game) {
    if (_attempts == 0) return 0;
    final accuracy = _correct / _attempts;
    final accuracyBonus = (accuracy * 10).round();
    return switch (game) {
      TrainingGameType.wordRush =>
        (_correct * 2 + _bestStreak * 2 + accuracyBonus).clamp(0, 80).toInt(),
      TrainingGameType.survival =>
        (_correct * 3 + _nodeRewards * 10 + _revives * 5 + accuracyBonus)
            .clamp(0, 90)
            .toInt(),
      TrainingGameType.spelling =>
        (_correct * 5 + accuracyBonus).clamp(0, 80).toInt(),
    };
  }

  Future<void> _finishTraining() async {
    final game = _game ?? TrainingGameType.fromId(widget.gameId);
    if (game == null) return;
    if (_isSubmitting) return;
    _timer?.cancel();
    if (_attempts == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('本轮还没有有效答题，不计入训练记录。')));
      context.go('/training');
      return;
    }
    setState(() => _isSubmitting = true);
    final result = LessonResult(
      lessonId: game.id,
      lessonTitle: widget.mistakesOnly ? '${game.title} · 错词再练' : game.title,
      totalQuestions: _attempts,
      correctAnswers: _correct,
      xpEarned: _xpFor(game),
      mistakes: List.unmodifiable(_mistakes),
      completedAt: DateTime.now(),
    );
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .completeTraining(
          result: result,
          gameId: game.id,
          startedAt: _startedAt,
          exerciseRecords: List.unmodifiable(_records),
        );
    if (!mounted) return;
    if (!succeeded) {
      setState(() => _isSubmitting = false);
      return;
    }
    context.go(
      '/lesson/${game.id}/result',
      extra: LessonResultViewArgs(
        result: result,
        source: LessonResultSource.training,
      ),
    );
  }
}

class _TrainingStatusLine extends StatelessWidget {
  const _TrainingStatusLine({
    required this.game,
    required this.progress,
    required this.remainingSeconds,
    required this.correct,
    required this.attempts,
    required this.streak,
    required this.bestStreak,
    required this.revives,
    required this.nodeRewards,
    required this.accuracy,
  });

  final TrainingGameType game;
  final double progress;
  final int remainingSeconds;
  final int correct;
  final int attempts;
  final int streak;
  final int bestStreak;
  final int revives;
  final int nodeRewards;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppTheme.progressTrack(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              game == TrainingGameType.survival
                  ? AppTheme.coral
                  : AppTheme.teal,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (game == TrainingGameType.wordRush)
              PillLabel(
                label: '${remainingSeconds}s',
                icon: Icons.timer_outlined,
                color: AppTheme.coral,
              ),
            PillLabel(
              label: '正确 $correct/$attempts',
              icon: Icons.check_rounded,
            ),
            PillLabel(
              label: '连击 $streak',
              icon: Icons.bolt,
              color: AppTheme.mango,
            ),
            PillLabel(label: '准确率 $accuracy%', icon: Icons.insights_outlined),
            if (game == TrainingGameType.survival)
              PillLabel(
                label: '复活 $revives · 节点 $nodeRewards',
                icon: Icons.favorite_border_rounded,
                color: AppTheme.coral,
              ),
            if (game == TrainingGameType.wordRush)
              PillLabel(
                label: '最佳 $bestStreak',
                icon: Icons.local_fire_department_outlined,
              ),
          ],
        ),
      ],
    );
  }
}

class _TrainingPromptPanel extends StatelessWidget {
  const _TrainingPromptPanel({
    required this.game,
    required this.question,
    required this.mistakesOnly,
  });

  final TrainingGameType game;
  final QuizQuestion question;
  final bool mistakesOnly;

  @override
  Widget build(BuildContext context) {
    final promptType = game == TrainingGameType.spelling
        ? question.id.split('-').last
        : '';
    final isAudioSpelling =
        game == TrainingGameType.spelling &&
        (int.tryParse(promptType) ?? 0) % 3 == 1;
    return Column(
      children: [
        ImageCueBadge(cue: question.word.imageCue, size: 104),
        const SizedBox(height: 14),
        Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (isAudioSpelling) ...[
          const SizedBox(height: 10),
          Center(
            child: PronunciationControls(
              word: question.word.word,
              compact: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            PillLabel(label: game.title, icon: game.icon, color: AppTheme.cyan),
            PillLabel(label: mistakesOnly ? '错词再练' : '真实题源'),
            PillLabel(label: question.word.difficulty, color: AppTheme.coral),
          ],
        ),
      ],
    );
  }
}

class _ChoiceInput extends StatelessWidget {
  const _ChoiceInput({
    required this.question,
    required this.selected,
    required this.checked,
    required this.onSelected,
  });

  final QuizQuestion question;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in question.options)
          _ChoiceAnswerButton(
            option: option,
            answer: question.answer,
            selected: selected,
            checked: checked,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _ChoiceAnswerButton extends StatelessWidget {
  const _ChoiceAnswerButton({
    required this.option,
    required this.answer,
    required this.selected,
    required this.checked,
    required this.onSelected,
  });

  final String option;
  final String answer;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelected;

  bool get _isCorrect => option.toLowerCase() == answer.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == option;
    final background = !checked
        ? Colors.transparent
        : _isCorrect
        ? AppTheme.mint
        : isSelected
        ? theme.colorScheme.errorContainer
        : Colors.transparent;
    final borderColor = !checked
        ? theme.colorScheme.outlineVariant
        : _isCorrect
        ? AppTheme.teal
        : isSelected
        ? theme.colorScheme.error
        : theme.colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 66,
        child: OutlinedButton(
          onPressed: checked ? null : () => onSelected(option),
          style: OutlinedButton.styleFrom(
            splashFactory: checked ? NoSplash.splashFactory : null,
            backgroundColor: background,
            disabledBackgroundColor: background,
            foregroundColor: theme.colorScheme.onSurface,
            disabledForegroundColor: theme.colorScheme.onSurface,
            side: BorderSide(
              color: borderColor,
              width: isSelected || _isCorrect ? 2 : 1,
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
              if (checked && isSelected)
                Icon(
                  _isCorrect
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                ),
              if (checked && !isSelected && _isCorrect)
                const Icon(Icons.check_circle_outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpellingInput extends StatelessWidget {
  const _SpellingInput({
    required this.controller,
    required this.checked,
    required this.isCorrect,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool checked;
  final bool isCorrect;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: !checked,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: '输入英文拼写',
        prefixIcon: const Icon(Icons.edit_outlined),
        suffixIcon: checked
            ? Icon(
                isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isCorrect
                    ? AppTheme.success
                    : Theme.of(context).colorScheme.error,
              )
            : null,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TrainingFeedback extends StatelessWidget {
  const _TrainingFeedback({
    required this.isCorrect,
    required this.question,
    required this.game,
    required this.revives,
    required this.reviveConsumed,
  });

  final bool isCorrect;
  final QuizQuestion question;
  final TrainingGameType game;
  final int revives;
  final bool reviveConsumed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? AppTheme.success : theme.colorScheme.error;
    final survivalMessage = game == TrainingGameType.survival && !isCorrect
        ? (reviveConsumed ? '已消耗一次复活机会，继续闯关。' : '复活机会已用完，本轮结束。')
        : question.explanation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCorrect ? '回答正确，连击继续！' : survivalMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Word _wordFromCustom(CustomWord word) {
  return Word(
    id: word.id,
    word: word.word,
    phonetic: '',
    meaning: word.meaning,
    definition: word.note.isEmpty ? word.meaning : word.note,
    partOfSpeech: 'word',
    exampleSentence: word.exampleSentence,
    exampleTranslation: '',
    imageCue: word.word.trim().isEmpty
        ? '?'
        : word.word.trim().characters.first.toUpperCase(),
    difficulty: word.difficulty,
    tags: [word.tag],
  );
}
