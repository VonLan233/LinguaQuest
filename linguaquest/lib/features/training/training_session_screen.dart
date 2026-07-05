import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/exercise_record.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quiz/lesson_result_screen.dart';

enum TrainingGameType {
  wordRush('word-rush', AppIcons.timer),
  survival('survival', AppIcons.stairs),
  spelling('spelling', AppIcons.editNote),
  listeningSprint('listening-sprint', AppIcons.hearing);

  const TrainingGameType(this.id, this.icon);

  final String id;
  final IconData icon;

  static TrainingGameType? fromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }

  String title(AppLocalizations l10n) => switch (this) {
    TrainingGameType.wordRush => l10n.trainingSpeedGame,
    TrainingGameType.survival => l10n.trainingSurvivor,
    TrainingGameType.spelling => l10n.trainingSpelling,
    TrainingGameType.listeningSprint => l10n.trainingListening,
  };
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
  bool _listeningRevealed = false;
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
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final game = _game ?? TrainingGameType.fromId(widget.gameId);
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trainingEntryMissingTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(
                title: l10n.trainingEntryMissingHeader,
                subtitle: l10n.trainingEntryMissingSubtitle,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/training'),
                icon: const Icon(AppIcons.arrowBack),
                label: Text(l10n.trainingBack),
              ),
            ],
          ),
        ),
      );
    }
    _ensureQuestions(state, game, l10n);
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(game.title(l10n))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(
                title: l10n.trainingSourceInsufficientTitle,
                subtitle: l10n.trainingSourceInsufficientSubtitle,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/training'),
                icon: const Icon(AppIcons.arrowBack),
                label: Text(l10n.trainingBack),
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
          title: Text(
            widget.mistakesOnly ? l10n.trainingMistakesOnly : game.title(l10n),
          ),
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
                          language: state.currentLanguage,
                          onListeningPlayed: () =>
                              setState(() => _listeningRevealed = true),
                        ),
                        const SizedBox(height: 18),
                        if (game == TrainingGameType.spelling)
                          _SpellingInput(
                            controller: _textController,
                            checked: _checked,
                            isCorrect: _lastCorrect,
                            onChanged: () => setState(() {}),
                          )
                        else if (game == TrainingGameType.listeningSprint &&
                            !_listeningRevealed &&
                            !_checked)
                          _ListeningRevealHint(
                            message: l10n.trainingListeningRevealHint,
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
                  AppPrimaryButton(
                    onPressed: _canSubmitSpelling
                        ? () => _submitAnswer(_textController.text.trim())
                        : null,
                    icon: _checked ? AppIcons.arrowForward : AppIcons.check,
                    label: _checked
                        ? l10n.trainingNextQuestion
                        : l10n.trainingSubmitSpelling,
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
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.trainingExitTitle),
          content: Text(l10n.trainingExitContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.trainingContinue),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(AppIcons.exitToApp),
              label: Text(l10n.trainingExit),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    context.go('/training');
  }

  void _ensureQuestions(
    AppState state,
    TrainingGameType game,
    AppLocalizations l10n,
  ) {
    if (_initialized && _game == game) return;
    _game = game;
    final words = _sourceWordsForGame(state, game);
    var distinctWords = _distinctWords(words);
    final minimumWords = game == TrainingGameType.spelling ? 1 : 3;
    if (!widget.mistakesOnly &&
        game == TrainingGameType.wordRush &&
        distinctWords.length < minimumWords) {
      distinctWords = _distinctWords(state.trainingWords);
    }
    if (distinctWords.length < minimumWords) {
      _initialized = true;
      return;
    }
    final localeCode = Localizations.localeOf(context).languageCode;
    _questions
      ..clear()
      ..addAll(_buildQuestions(game, distinctWords, l10n, localeCode));
    _initialized = true;
    _questionStartedAt = DateTime.now();
    _timer?.cancel();
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
      TrainingGameType.listeningSprint => [...currentBookWords, ...weakWords],
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

  List<QuizQuestion> _buildQuestions(
    TrainingGameType game,
    List<Word> words,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final count = switch (game) {
      TrainingGameType.wordRush => words.length * 4,
      TrainingGameType.survival => _survivalQuestionCount,
      TrainingGameType.spelling => _spellingQuestionCount,
      TrainingGameType.listeningSprint => _survivalQuestionCount,
    };
    return [
      for (var index = 0; index < count; index++)
        _questionFor(
          game,
          words[index % words.length],
          words,
          index,
          l10n,
          localeCode,
        ),
    ];
  }

  QuizQuestion _questionFor(
    TrainingGameType game,
    Word word,
    List<Word> words,
    int index,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final wordMeaning = word.primaryDefinitionFor(localeCode);
    switch (game) {
      case TrainingGameType.wordRush:
        return QuizQuestion(
          id: '${game.id}-${word.id}-$index',
          type: QuizQuestionType.meaningChoice,
          prompt: l10n.trainingPromptWordRush(word.word),
          answer: wordMeaning,
          options: _options(
            answer: wordMeaning,
            values: words.map((item) => item.primaryDefinitionFor(localeCode)),
            offset: index,
          ),
          explanation: l10n.trainingExplanationWordRush(
            word.word,
            wordMeaning,
            word.exampleSentence,
          ),
          word: word,
        );
      case TrainingGameType.survival:
        final variant = index % 3;
        if (variant == 1) {
          return QuizQuestion(
            id: '${game.id}-${word.id}-$index',
            type: QuizQuestionType.chineseChoice,
            prompt: l10n.trainingPromptChineseChoice(wordMeaning),
            answer: word.word,
            options: _options(
              answer: word.word,
              values: words.map((item) => item.word),
              offset: index,
            ),
            explanation: l10n.trainingExplanationChineseChoice(
              wordMeaning,
              word.word,
            ),
            word: word,
          );
        }
        final hasExample = word.exampleSentence.trim().isNotEmpty;
        return QuizQuestion(
          id: '${game.id}-${word.id}-$index',
          type: variant == 2 && hasExample
              ? QuizQuestionType.contextChoice
              : QuizQuestionType.meaningChoice,
          prompt: variant == 2 && hasExample
              ? l10n.trainingPromptContextChoice(word.exampleSentence)
              : l10n.trainingPromptMeaningChoice(word.word),
          answer: wordMeaning,
          options: _options(
            answer: wordMeaning,
            values: words.map((item) => item.primaryDefinitionFor(localeCode)),
            offset: index,
          ),
          explanation: l10n.trainingExplanationMeaningChoice(
            word.word,
            wordMeaning,
          ),
          word: word,
        );
      case TrainingGameType.spelling:
        final variant = index % 3;
        final prompt = switch (variant) {
          0 => l10n.trainingPromptChineseSpelling(wordMeaning),
          1 => l10n.trainingPromptAudioSpelling(
            word.phonetic.isEmpty ? word.word : word.phonetic,
          ),
          _ => l10n.trainingPromptContextSpelling(
            _blankExample(word, localeCode),
          ),
        };
        return QuizQuestion(
          id: '${game.id}-${word.id}-$index',
          type: QuizQuestionType.spelling,
          prompt: prompt,
          answer: word.word,
          options: const [],
          explanation: l10n.trainingExplanationSpelling(
            word.word,
            word.exampleSentence,
          ),
          word: word,
        );
      case TrainingGameType.listeningSprint:
        return buildListeningQuestion(
          word,
          words,
          index,
          l10n.trainingPromptListening,
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
    return List.unmodifiable(options..shuffle(Random(offset)));
  }

  String _blankExample(Word word, String localeCode) {
    final expression = RegExp(RegExp.escape(word.word), caseSensitive: false);
    final sentence = word.exampleSentence.trim();
    if (sentence.isEmpty) {
      return '____ (${word.primaryDefinitionFor(localeCode)})';
    }
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
        game == TrainingGameType.survival ||
        game == TrainingGameType.listeningSprint) {
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
      TrainingGameType.listeningSprint => _index >= _questions.length - 1,
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
      _listeningRevealed = false;
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
      case TrainingGameType.listeningSprint:
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
    if (game == TrainingGameType.listeningSprint) {
      return ReviewDimension.listening;
    }
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
      TrainingGameType.listeningSprint =>
        (_correct * 4 + accuracyBonus).clamp(0, 80).toInt(),
    };
  }

  Future<void> _finishTraining() async {
    final game = _game ?? TrainingGameType.fromId(widget.gameId);
    if (game == null) return;
    if (_isSubmitting) return;
    _timer?.cancel();
    if (_attempts == 0) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.trainingNoEffectiveAnswers)));
      context.go('/training');
      return;
    }
    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context);
    final gameTitle = game.title(l10n);
    final result = LessonResult(
      lessonId: game.id,
      lessonTitle: widget.mistakesOnly
          ? l10n.trainingResultMistakesSuffix(gameTitle)
          : gameTitle,
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
        AppProgressBar(value: progress, height: 12),
        const SizedBox(height: AppTokens.s12),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            if (game == TrainingGameType.wordRush)
              AppPill(
                label: '${remainingSeconds}s',
                icon: AppIcons.timer,
                variant: PillVariant.streak,
              ),
            AppPill(
              label: AppLocalizations.of(
                context,
              ).trainingCorrectAttempts(correct, attempts),
              icon: AppIcons.check,
              variant: PillVariant.success,
            ),
            AppPill(
              label: AppLocalizations.of(context).trainingStreak(streak),
              icon: AppIcons.bolt,
              variant: PillVariant.xp,
            ),
            AppPill(
              label: AppLocalizations.of(
                context,
              ).trainingAccuracyValue(accuracy),
              icon: AppIcons.insights,
              variant: PillVariant.primary,
            ),
            if (game == TrainingGameType.survival)
              AppPill(
                label: AppLocalizations.of(
                  context,
                ).trainingSurvivalResources(nodeRewards, revives),
                icon: AppIcons.favorite,
                variant: PillVariant.streak,
              ),
            if (game == TrainingGameType.wordRush)
              AppPill(
                label: AppLocalizations.of(
                  context,
                ).trainingBestStreak(bestStreak),
                icon: AppIcons.localFireDepartment,
                variant: PillVariant.xp,
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
    this.language = '',
    this.onListeningPlayed,
  });

  final TrainingGameType game;
  final QuizQuestion question;
  final bool mistakesOnly;
  final String language;
  final VoidCallback? onListeningPlayed;

  @override
  Widget build(BuildContext context) {
    final promptType = game == TrainingGameType.spelling
        ? question.id.split('-').last
        : '';
    final isAudioSpelling =
        game == TrainingGameType.spelling &&
        (int.tryParse(promptType) ?? 0) % 3 == 1;
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
          if (isAudioSpelling) ...[
            const SizedBox(height: 10),
            Center(
              child: PronunciationControls(
                word: question.word.word,
                compact: true,
                language: language,
              ),
            ),
          ],
          if (game == TrainingGameType.listeningSprint) ...[
            const SizedBox(height: 10),
            Center(
              child: PronunciationControls(
                word: question.word.word,
                audioUKUrl: question.word.audioUKUrl,
                audioUSUrl: question.word.audioUSUrl,
                compact: true,
                language: language,
                onPlayed: onListeningPlayed,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            alignment: WrapAlignment.center,
            children: [
              AppPill(
                label: game.title(AppLocalizations.of(context)),
                icon: game.icon,
                variant: PillVariant.primary,
              ),
              AppPill(
                label: mistakesOnly
                    ? AppLocalizations.of(context).trainingMistakesOnly
                    : AppLocalizations.of(context).trainingRealSource,
                variant: PillVariant.success,
              ),
              AppPill(
                label: question.word.difficulty,
                variant: PillVariant.streak,
              ),
            ],
          ),
        ],
      ),
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

  bool _isCorrectOption(String option) {
    return option.toLowerCase() == question.answer.toLowerCase();
  }

  ChoiceState _optionState(String option) {
    if (!checked) {
      return selected == option ? ChoiceState.selected : ChoiceState.idle;
    }
    if (_isCorrectOption(option)) return ChoiceState.correct;
    if (selected == option) return ChoiceState.wrong;
    return ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s12),
            child: WordChoiceButton(
              letter: String.fromCharCode(65 + i),
              text: question.options[i],
              state: _optionState(question.options[i]),
              onTap: checked ? null : () => onSelected(question.options[i]),
            ),
          ),
      ],
    );
  }
}

class _ListeningRevealHint extends StatelessWidget {
  const _ListeningRevealHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(AppIcons.hearing, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      readOnly: checked,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).trainingSpellingInputLabel,
        prefixIcon: const Icon(AppIcons.edit),
        suffixIcon: checked
            ? Icon(
                isCorrect ? AppIcons.checkCircle : AppIcons.cancel,
                color: isCorrect
                    ? AppTokens.successColor(context)
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
    final background = isCorrect ? AppTokens.successSoft : AppTokens.streakSoft;
    final foreground = isCorrect
        ? AppTokens.successSoftText
        : AppTokens.streakSoftText;
    final survivalMessage = game == TrainingGameType.survival && !isCorrect
        ? (reviveConsumed
              ? AppLocalizations.of(context).trainingReviveConsumed
              : AppLocalizations.of(context).trainingReviveExhausted)
        : question.explanation;
    return AppCard(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCorrect ? AppIcons.checkCircle : AppIcons.cancel,
                color: foreground,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  isCorrect
                      ? AppLocalizations.of(context).trainingCorrectFeedback
                      : survivalMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Word _wordFromCustom(CustomWord word) {
  return wordFromCustomWord(word);
}

/// Builds a listening-choice question: the prompt is an instruction (the word
/// is spoken, not shown); options are candidate words incl. the answer.
QuizQuestion buildListeningQuestion(
  Word word,
  List<Word> words,
  int index,
  String prompt,
) {
  final values = words.map((w) => w.word).toList();
  final options = <String>[];
  final seen = <String>{};
  void add(String v) {
    final key = v.trim().toLowerCase();
    if (v.trim().isNotEmpty && seen.add(key)) options.add(v.trim());
  }
  add(word.word);
  for (var step = 0; step < values.length && options.length < 4; step++) {
    add(values[(index + step + 1) % values.length]);
  }
  return QuizQuestion(
    id: 'listening-sprint-${word.id}-$index',
    type: QuizQuestionType.listeningWordChoice,
    prompt: prompt,
    answer: word.word,
    options: List.unmodifiable(options..shuffle(Random(index))),
    explanation: word.exampleSentence,
    word: word,
  );
}
