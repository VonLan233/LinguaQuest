import 'models/lesson.dart';

List<Lesson> lessonsFromWordBook(WordBook book, {int wordsPerLesson = 3}) {
  if (book.words.isEmpty) return const [];
  final lessons = <Lesson>[];
  for (var start = 0; start < book.words.length; start += wordsPerLesson) {
    final words = book.words.skip(start).take(wordsPerLesson).toList();
    final lessonNumber = lessons.length + 1;
    lessons.add(
      Lesson(
        id: '${book.id}-lesson-$lessonNumber',
        title: '${book.title} $lessonNumber',
        section: book.title,
        description: book.description,
        status: lessonNumber == 1 ? 'current' : 'locked',
        xpReward: 20 + words.length,
        estimatedMinutes: words.length.clamp(5, 15).toInt(),
        words: words,
        questions: buildQuestionsForWords(
          lessonId: '${book.id}-lesson-$lessonNumber',
          words: words,
          distractorWords: book.words,
        ),
      ),
    );
  }
  return [...lessons, ...trainingLessonsFromWordBook(book)];
}

List<Lesson> trainingLessonsFromWordBook(WordBook book) {
  final words = book.words;
  if (words.length < 3) return const [];
  final distractors = words;
  final speedWords = _takeTrainingWords(words, 0, 3);
  final gauntletWords = _takeTrainingWords(words, 3, 3);
  final spellingWords = _takeTrainingWords(words, 6, words.length >= 4 ? 4 : 3);
  final clozeWords = _takeTrainingWords(words, 10, 3);
  final listeningWords = _takeTrainingWords(words, 13, 3);

  return [
    _trainingLesson(
      id: '${book.id}-training-speed',
      title: '抢词挑战',
      description: '从当前词书中快速辨义，按正确率结算训练积分。',
      xpReward: 25,
      words: speedWords,
      distractorWords: distractors,
    ),
    _trainingLesson(
      id: '${book.id}-training-gauntlet',
      title: '一站到底',
      description: '连续完成多题型挑战，错词会进入弱项和后续复习记录。',
      xpReward: 30,
      words: gauntletWords,
      distractorWords: distractors,
    ),
    _spellingLesson(
      id: '${book.id}-training-spelling',
      title: '单词拼写专项',
      description: '围绕当前词书进行输入训练，强化可产出能力。',
      xpReward: 24,
      words: spellingWords,
    ),
    _trainingLesson(
      id: '${book.id}-training-cloze',
      title: '文章挖词',
      description: '把当前词书词汇放回短文语境，用选择和拼写连接阅读理解。',
      xpReward: 28,
      words: clozeWords,
      distractorWords: distractors,
    ),
    _listeningLesson(
      id: '${book.id}-training-listening',
      title: '听音速答',
      description: '播放当前词书词汇发音后选择单词或释义，训练听力识别。',
      xpReward: 20,
      words: listeningWords,
      distractorWords: distractors,
    ),
  ];
}

List<QuizQuestion> buildQuestionsForWords({
  required String lessonId,
  required List<Word> words,
  required List<Word> distractorWords,
}) {
  if (words.length >= 3) {
    return [
      _questionForWord(
        lessonId: lessonId,
        word: words[0],
        index: 0,
        type: QuizQuestionType.meaningChoice,
        distractorWords: distractorWords,
      ),
      _questionForWord(
        lessonId: lessonId,
        word: words[1],
        index: 1,
        type: QuizQuestionType.chineseChoice,
        distractorWords: distractorWords,
      ),
      _questionForWord(
        lessonId: lessonId,
        word: words[2],
        index: 2,
        type: QuizQuestionType.contextChoice,
        distractorWords: distractorWords,
      ),
      _questionForWord(
        lessonId: lessonId,
        word: words[2],
        index: 3,
        type: QuizQuestionType.spelling,
        distractorWords: distractorWords,
      ),
    ];
  }
  return [
    for (var index = 0; index < words.length; index++)
      _questionForWord(
        lessonId: lessonId,
        word: words[index],
        index: index,
        type: _typeForIndex(index),
        distractorWords: distractorWords,
      ),
  ];
}

QuizQuestionType _typeForIndex(int index) {
  switch (index % 4) {
    case 0:
      return QuizQuestionType.meaningChoice;
    case 1:
      return QuizQuestionType.chineseChoice;
    case 2:
      return QuizQuestionType.contextChoice;
    default:
      return QuizQuestionType.spelling;
  }
}

QuizQuestion _questionForWord({
  required String lessonId,
  required Word word,
  required int index,
  required QuizQuestionType type,
  required List<Word> distractorWords,
}) {
  switch (type) {
    case QuizQuestionType.chineseChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: '根据中文释义选择英文单词：${word.meaning}',
        answer: word.word,
        options: _choiceOptions(
          answer: word.word,
          fallbackDistractors: distractorWords.map((item) => item.word),
        ),
        explanation:
            '“${word.meaning}”对应“${word.word}”。${word.exampleSentence}',
        word: word,
      );
    case QuizQuestionType.contextChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: '根据语境选择“${word.word}”的中文释义：${word.exampleSentence}',
        answer: word.meaning,
        options: _choiceOptions(
          answer: word.meaning,
          fallbackDistractors: distractorWords.map((item) => item.meaning),
        ),
        explanation:
            '这里的“${word.word}”表示${word.meaning}。${word.exampleTranslation}',
        word: word,
      );
    case QuizQuestionType.spelling:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: '根据释义拼写单词：${word.meaning}',
        answer: word.word,
        options: const [],
        explanation: '正确拼写是“${word.word}”。',
        word: word,
      );
    case QuizQuestionType.listeningWordChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: '播放发音，选择听到的英文单词。',
        answer: word.word,
        options: _choiceOptions(
          answer: word.word,
          fallbackDistractors: distractorWords.map((item) => item.word),
        ),
        explanation: '你听到的是“${word.word}”。${word.exampleSentence}',
        word: word,
      );
    case QuizQuestionType.listeningMeaningChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: '播放发音，选择对应的中文释义。',
        answer: word.meaning,
        options: _choiceOptions(
          answer: word.meaning,
          fallbackDistractors: distractorWords.map((item) => item.meaning),
        ),
        explanation: '“${word.word}”对应${word.meaning}。',
        word: word,
      );
    case QuizQuestionType.meaningChoice:
    case QuizQuestionType.imageChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: QuizQuestionType.meaningChoice,
        prompt: '选择“${word.word}”的中文释义。',
        answer: word.meaning,
        options: _choiceOptions(
          answer: word.meaning,
          fallbackDistractors: distractorWords.map((item) => item.meaning),
        ),
        explanation:
            '“${word.word}”的意思是${word.meaning}。${word.exampleSentence}',
        word: word,
      );
  }
}

List<String> _choiceOptions({
  required String answer,
  required Iterable<String> fallbackDistractors,
}) {
  final options = <String>[];
  final seen = <String>{};

  void addOption(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    final key = cleaned.toLowerCase();
    if (seen.add(key)) options.add(cleaned);
  }

  addOption(answer);
  for (final option in fallbackDistractors) {
    if (option == answer) continue;
    addOption(option);
    if (options.length == 4) break;
  }

  return List.unmodifiable(options);
}

List<Word> _takeTrainingWords(List<Word> words, int start, int count) {
  return [
    for (var index = 0; index < count; index++)
      words[(start + index) % words.length],
  ];
}

Lesson _trainingLesson({
  required String id,
  required String title,
  required String description,
  required int xpReward,
  required List<Word> words,
  required List<Word> distractorWords,
}) {
  return Lesson(
    id: id,
    title: title,
    section: '训练场',
    description: description,
    status: 'locked',
    xpReward: xpReward,
    estimatedMinutes: 5,
    words: words,
    questions: buildQuestionsForWords(
      lessonId: id,
      words: words,
      distractorWords: distractorWords,
    ),
  );
}

Lesson _spellingLesson({
  required String id,
  required String title,
  required String description,
  required int xpReward,
  required List<Word> words,
}) {
  return Lesson(
    id: id,
    title: title,
    section: '训练场',
    description: description,
    status: 'locked',
    xpReward: xpReward,
    estimatedMinutes: 5,
    words: words,
    questions: [
      for (var index = 0; index < words.length; index++)
        QuizQuestion(
          id: '$id-q${index + 1}',
          type: QuizQuestionType.spelling,
          prompt: '根据释义拼写单词：${words[index].meaning}',
          answer: words[index].word,
          options: const [],
          explanation:
              '正确拼写是“${words[index].word}”。${words[index].exampleSentence}',
          word: words[index],
        ),
    ],
  );
}

Lesson _listeningLesson({
  required String id,
  required String title,
  required String description,
  required int xpReward,
  required List<Word> words,
  required List<Word> distractorWords,
}) {
  return Lesson(
    id: id,
    title: title,
    section: '训练场',
    description: description,
    status: 'locked',
    xpReward: xpReward,
    estimatedMinutes: 5,
    words: words,
    questions: [
      _questionForWord(
        lessonId: id,
        word: words[0],
        index: 0,
        type: QuizQuestionType.listeningWordChoice,
        distractorWords: distractorWords,
      ),
      _questionForWord(
        lessonId: id,
        word: words[1],
        index: 1,
        type: QuizQuestionType.listeningMeaningChoice,
        distractorWords: distractorWords,
      ),
      _questionForWord(
        lessonId: id,
        word: words[2],
        index: 2,
        type: QuizQuestionType.listeningWordChoice,
        distractorWords: distractorWords,
      ),
      _questionForWord(
        lessonId: id,
        word: words[2],
        index: 3,
        type: QuizQuestionType.spelling,
        distractorWords: distractorWords,
      ),
    ],
  );
}
