import 'dart:math';

import 'models/lesson.dart';

List<Lesson> lessonsFromWordBook(WordBook book, {int wordsPerLesson = 3}) {
  if (book.words.isEmpty) return const [];
  final lessons = <Lesson>[];
  for (var start = 0; start < book.words.length; start += wordsPerLesson) {
    final words = book.words.skip(start).take(wordsPerLesson).toList();
    final lessonNumber = lessons.length + 1;
    final lessonId = '${book.id}-lesson-$lessonNumber';
    lessons.add(
      Lesson(
        id: lessonId,
        title: '${book.title} 第 $lessonNumber 组',
        section: book.title,
        description: book.description,
        status: lessonNumber == 1 ? 'current' : 'locked',
        xpReward: 20 + words.length,
        estimatedMinutes: words.length.clamp(5, 15).toInt(),
        words: words,
        questions: buildQuestionsForWords(
          lessonId: lessonId,
          words: words.take(4).toList(),
          distractorWords: book.words,
        ),
      ),
    );
  }
  return [...lessons, ...trainingLessonsFromWordBook(book)];
}

List<Lesson> trainingLessonsFromWordBook(WordBook book) {
  if (book.words.length < 4) return const [];
  return [
    _trainingLesson(
      id: '${book.id}-training-speed',
      title: '${book.title} · 抢词挑战',
      description: '从当前词书抽题，快速辨认词义和英文拼写。',
      xpReward: 25,
      words: _takeTrainingWords(book.words, 0, 4),
      distractorWords: book.words,
    ),
    _trainingLesson(
      id: '${book.id}-training-gauntlet',
      title: '${book.title} · 一站到底',
      description: '连续完成多题型挑战，错词会进入后续复习记录。',
      xpReward: 30,
      words: _takeTrainingWords(book.words, 4, 4),
      distractorWords: book.words,
    ),
    _spellingLesson(
      id: '${book.id}-training-spelling',
      title: '${book.title} · 单词拼写',
      description: '根据中文释义和语境输入英文，强化可产出能力。',
      xpReward: 24,
      words: _takeTrainingWords(book.words, 8, 4),
    ),
    _listeningLesson(
      id: '${book.id}-training-listening',
      title: '${book.title} · 听音速答',
      description: '围绕当前词书进行发音识别和词义选择。',
      xpReward: 22,
      words: _takeTrainingWords(book.words, 12, 4),
      distractorWords: book.words,
    ),
  ];
}

List<QuizQuestion> buildQuestionsForWords({
  required String lessonId,
  required List<Word> words,
  required List<Word> distractorWords,
  // [forceType] 供测试使用，强制所有题目使用指定题型。
  // 生产代码应保持 null，由 _typeForWord 自动选择。
  QuizQuestionType? forceType,
}) {
  return [
    for (var index = 0; index < words.length; index++)
      _questionForWord(
        lessonId: lessonId,
        word: words[index],
        index: index,
        type: forceType ?? _typeForWord(words[index]),
        distractorWords: distractorWords,
      ),
  ];
}

QuizQuestionType _typeForWord(Word word) {
  // 8 种题型轮转分布；优先保证有数据支撑的题型，无数据时自动降级。
  switch (_stableHash(word.id) % 8) {
    case 0:
      return QuizQuestionType.meaningChoice;
    case 1:
      return QuizQuestionType.chineseChoice;
    case 2:
      // 上下文题需要例句；HSK 词条不一定有，无例句时降级为 meaningChoice。
      return word.exampleSentence.trim().isEmpty
          ? QuizQuestionType.meaningChoice
          : QuizQuestionType.contextChoice;
    case 3:
      return QuizQuestionType.spelling;
    case 4:
      // 例句填空需要例句；无例句时降级为 meaningChoice。
      return word.exampleSentence.trim().isEmpty
          ? QuizQuestionType.meaningChoice
          : QuizQuestionType.sentenceCloze;
    case 5:
      // 易混词辨析总能生成（从干扰词池取），无需前置条件。
      return QuizQuestionType.confusableChoice;
    case 6:
      // 搭配选择需要 collocations；无搭配时降级在 _questionForWord 中处理。
      return QuizQuestionType.collocationChoice;
    default:
      // 词形变化需要 derivatives；无词形变体时降级在 _questionForWord 中处理。
      return QuizQuestionType.derivativeChoice;
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
        prompt: 'Select the Chinese word for: ${word.meaning}',
        answer: word.word,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.word),
          answer: word.word,
          fallbackDistractors: distractorWords.map((item) => item.word),
        ),
        explanation: '"${word.meaning}" is "${word.word}" (${word.phonetic}).',
        word: word,
      );
    case QuizQuestionType.contextChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt:
            'Choose the English meaning of "${word.word}" in: ${word.exampleSentence}',
        answer: word.meaning,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.meaning),
          answer: word.meaning,
          fallbackDistractors: distractorWords.map((item) => item.meaning),
        ),
        explanation:
            'Here "${word.word}" means ${word.meaning}. ${word.exampleTranslation}',
        word: word,
      );
    case QuizQuestionType.spelling:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Type the pinyin for "${word.word}" (${word.meaning}).',
        answer: word.phonetic,
        options: const [],
        explanation: 'The pinyin is "${word.phonetic}".',
        word: word,
      );
    case QuizQuestionType.listeningWordChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Play the audio and choose the word you hear.',
        answer: word.word,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.word),
          answer: word.word,
          fallbackDistractors: distractorWords.map((item) => item.word),
        ),
        explanation: 'You heard "${word.word}" (${word.phonetic}).',
        word: word,
      );
    case QuizQuestionType.listeningMeaningChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Play the audio and choose the English meaning.',
        answer: word.meaning,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.meaning),
          answer: word.meaning,
          fallbackDistractors: distractorWords.map((item) => item.meaning),
        ),
        explanation: '"${word.word}" means ${word.meaning}.',
        word: word,
      );
    case QuizQuestionType.sentenceCloze:
      // 例句填空：把例句中的目标词替换为 ____，让学习者从选项中选回正确词。
      // 若无例句，降级为 meaningChoice（数据不足时安全回退）。
      if (word.exampleSentence.trim().isEmpty) {
        return QuizQuestion(
          id: '$lessonId-q$index',
          // 降级原因：该词无例句，sentenceCloze 无法生成，回退到 meaningChoice。
          type: QuizQuestionType.meaningChoice,
          prompt: 'Select the English meaning of "${word.word}".',
          answer: word.meaning,
          options: _choiceOptions(
            seed: _optionSeed(lessonId, word.id, word.meaning),
            answer: word.meaning,
            fallbackDistractors: distractorWords.map((item) => item.meaning),
          ),
          explanation: '"${word.word}" means ${word.meaning}. (No example sentence available.)',
          word: word,
        );
      }
      final blankSentence = _blankOutWord(word.exampleSentence, word.word);
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Fill in the blank: $blankSentence',
        answer: word.word,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.word),
          answer: word.word,
          fallbackDistractors: distractorWords.map((item) => item.word),
        ),
        explanation: 'The correct word is "${word.word}": ${word.exampleSentence}',
        word: word,
      );

    case QuizQuestionType.confusableChoice:
      // 易混词辨析：用 synonyms（近义词）构建干扰项；无 synonyms 时从干扰词池取。
      // 答案为词的中文释义，从近义词或同级词中选出对应目标词的选项。
      final confusableSynonyms = word.synonyms.isNotEmpty
          ? word.synonyms
          : distractorWords.map((w) => w.word).toList();
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Which word best matches: "${word.meaning}"?',
        answer: word.word,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.word),
          answer: word.word,
          fallbackDistractors: confusableSynonyms,
        ),
        explanation: '"${word.word}" means ${word.meaning}. '
            'Confusable words: ${confusableSynonyms.take(3).join(', ')}.',
        word: word,
      );

    case QuizQuestionType.collocationChoice:
      // 搭配选择：从 collocations 选出正确搭配，用干扰词拼出错误搭配。
      // 若词无 collocations 字段，降级为 meaningChoice（数据不足时安全回退）。
      if (word.collocations.isEmpty) {
        return QuizQuestion(
          id: '$lessonId-q$index',
          // 降级原因：该词无搭配数据，collocationChoice 无法生成，回退到 meaningChoice。
          type: QuizQuestionType.meaningChoice,
          prompt: 'Select the English meaning of "${word.word}".',
          answer: word.meaning,
          options: _choiceOptions(
            seed: _optionSeed(lessonId, word.id, word.meaning),
            answer: word.meaning,
            fallbackDistractors: distractorWords.map((item) => item.meaning),
          ),
          explanation: '"${word.word}" means ${word.meaning}. (No collocation data available.)',
          word: word,
        );
      }
      final correctCollocation = word.collocations.first.phrase;
      final wrongCollocations = distractorWords
          .where((w) => w.id != word.id)
          .take(3)
          .map((w) => '${w.word} ${word.collocations.first.phrase.split(' ').skip(1).join(' ')}')
          .toList();
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Choose the correct collocation with "${word.word}":',
        answer: correctCollocation,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, correctCollocation),
          answer: correctCollocation,
          fallbackDistractors: wrongCollocations,
        ),
        explanation: 'The correct collocation is "$correctCollocation".',
        word: word,
      );

    case QuizQuestionType.derivativeChoice:
      // 词形变化：展示词义，让学习者从词形变体中选出正确的派生词。
      // 若词无 derivatives 字段，降级为 meaningChoice（数据不足时安全回退）。
      if (word.derivatives.isEmpty) {
        return QuizQuestion(
          id: '$lessonId-q$index',
          // 降级原因：该词无派生词数据，derivativeChoice 无法生成，回退到 meaningChoice。
          type: QuizQuestionType.meaningChoice,
          prompt: 'Select the English meaning of "${word.word}".',
          answer: word.meaning,
          options: _choiceOptions(
            seed: _optionSeed(lessonId, word.id, word.meaning),
            answer: word.meaning,
            fallbackDistractors: distractorWords.map((item) => item.meaning),
          ),
          explanation: '"${word.word}" means ${word.meaning}. (No derivative data available.)',
          word: word,
        );
      }
      final targetDerivative = word.derivatives.first;
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: type,
        prompt: 'Which is a correct word form derived from "${word.word}"?',
        answer: targetDerivative,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, targetDerivative),
          answer: targetDerivative,
          fallbackDistractors: [
            ...word.derivatives.skip(1),
            ...distractorWords.map((w) => w.word),
          ],
        ),
        explanation: '"$targetDerivative" is a derivative of "${word.word}" (${word.meaning}).',
        word: word,
      );

    case QuizQuestionType.meaningChoice:
    case QuizQuestionType.imageChoice:
      return QuizQuestion(
        id: '$lessonId-q$index',
        type: QuizQuestionType.meaningChoice,
        prompt: 'Select the English meaning of "${word.word}".',
        answer: word.meaning,
        options: _choiceOptions(
          seed: _optionSeed(lessonId, word.id, word.meaning),
          answer: word.meaning,
          fallbackDistractors: distractorWords.map((item) => item.meaning),
        ),
        explanation: '"${word.word}" means ${word.meaning}. ${word.exampleSentence}',
        word: word,
      );
  }
}

/// 把 [sentence] 中第一次出现的 [targetWord]（大小写不敏感）替换为 ____。
/// 若找不到，则在句末附加 "(____)".
String _blankOutWord(String sentence, String targetWord) {
  final pattern = RegExp(RegExp.escape(targetWord), caseSensitive: false);
  if (pattern.hasMatch(sentence)) {
    return sentence.replaceFirst(pattern, '____');
  }
  // 词的变形（如加了 -ed/-ing）可能导致精确匹配失败，退而附加括号提示
  return '$sentence (____)';
}

List<String> _choiceOptions({
  required int seed,
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
  return List.unmodifiable(options..shuffle(Random(seed)));
}

int _optionSeed(String lessonId, String wordId, String answer) {
  return _stableHash('$lessonId:$wordId:$answer');
}

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
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
    status: 'current',
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
    status: 'current',
    xpReward: xpReward,
    estimatedMinutes: 5,
    words: words,
    questions: [
      for (var index = 0; index < words.length; index++)
        QuizQuestion(
          id: '$id-q$index',
          type: QuizQuestionType.spelling,
          prompt:
              'Type the pinyin for "${words[index].word}" (${words[index].meaning}).',
          answer: words[index].phonetic,
          options: const [],
          explanation: 'The pinyin is "${words[index].phonetic}".',
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
    status: 'current',
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
        type: QuizQuestionType.spelling,
        distractorWords: distractorWords,
      ),
    ],
  );
}
