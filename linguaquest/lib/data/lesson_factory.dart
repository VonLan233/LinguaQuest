import 'dart:math';

import 'models/lesson.dart';
import 'models/word_entry.dart';

class LessonFactory {
  const LessonFactory({this.wordsPerLesson = 20});

  final int wordsPerLesson;

  List<Lesson> buildLessons({
    required String wordBookId,
    required String wordBookTitle,
    required List<WordEntry> entries,
  }) {
    if (entries.isEmpty) return [];
    final lessons = <Lesson>[];
    final random = Random(wordBookId.hashCode);

    for (var i = 0; i < entries.length; i += wordsPerLesson) {
      final batch = entries.sublist(
        i,
        (i + wordsPerLesson).clamp(0, entries.length),
      );
      final lessonIndex = (i ~/ wordsPerLesson) + 1;
      final words = _toWords(batch);
      final questions = _buildQuestions(batch, allEntries: entries, random: random);
      lessons.add(
        Lesson(
          id: '$wordBookId-lesson-$lessonIndex',
          title: '$wordBookTitle · 第 $lessonIndex 课',
          section: wordBookId,
          description: '从 ${batch.first.word} 到 ${batch.last.word}，共 ${batch.length} 词',
          status: lessonIndex == 1 ? 'current' : 'locked',
          xpReward: 25,
          estimatedMinutes: 8,
          words: words,
          questions: questions,
        ),
      );
    }

    return lessons;
  }

  List<Word> _toWords(List<WordEntry> entries) {
    return [
      for (final entry in entries)
        Word(
          id: entry.id,
          word: entry.word,
          phonetic: entry.phoneticUK.isNotEmpty
              ? entry.phoneticUK
              : entry.phoneticUS,
          meaning: entry.definitions.isNotEmpty ? entry.definitions.first : '',
          definition: entry.englishDefinitions.isNotEmpty
              ? entry.englishDefinitions.first
              : '',
          partOfSpeech: entry.partOfSpeech,
          exampleSentence: entry.exampleSentences.isNotEmpty
              ? entry.exampleSentences.first.en
              : '',
          exampleTranslation: entry.exampleSentences.isNotEmpty
              ? entry.exampleSentences.first.cn
              : '',
          imageCue: '',
          difficulty: _capitalize(entry.difficulty),
          tags: [...entry.examTags, entry.partOfSpeech].where((t) => t.isNotEmpty).toList(),
        ),
    ];
  }

  List<QuizQuestion> _buildQuestions(
    List<WordEntry> batch, {
    required List<WordEntry> allEntries,
    required Random random,
  }) {
    final questions = <QuizQuestion>[];
    for (var index = 0; index < batch.length; index++) {
      final entry = batch[index];
      final distractors = _pickDistractors(
        entry,
        allEntries: allEntries,
        count: 3,
        random: random,
      );

      // Meaning choice (English -> Chinese)
      questions.add(
        QuizQuestion(
          id: '${entry.id}-meaning',
          type: QuizQuestionType.meaningChoice,
          prompt: entry.word,
          answer: entry.definitions.isNotEmpty ? entry.definitions.first : entry.word,
          options: _shuffle([
            if (entry.definitions.isNotEmpty) entry.definitions.first else entry.word,
            ...distractors.map((d) => d.definitions.isNotEmpty ? d.definitions.first : d.word),
          ], random),
          explanation: entry.englishDefinitions.isNotEmpty
              ? entry.englishDefinitions.first
              : '',
          word: _toWords([entry]).first,
        ),
      );

      // Chinese choice (Chinese -> English)
      if (entry.definitions.isNotEmpty) {
        questions.add(
          QuizQuestion(
            id: '${entry.id}-chinese',
            type: QuizQuestionType.chineseChoice,
            prompt: entry.definitions.first,
            answer: entry.word,
            options: _shuffle([
              entry.word,
              ...distractors.map((d) => d.word),
            ], random),
            explanation: entry.exampleSentences.isNotEmpty
                ? entry.exampleSentences.first.en
                : '',
            word: _toWords([entry]).first,
          ),
        );
      }

      // Context choice (sentence with blank)
      if (entry.exampleSentences.isNotEmpty) {
        final sentence = entry.exampleSentences.first.en;
        final blanked = sentence.replaceFirst(
          RegExp(entry.word, caseSensitive: false),
          '_____',
        );
        if (blanked != sentence) {
          questions.add(
            QuizQuestion(
              id: '${entry.id}-context',
              type: QuizQuestionType.contextChoice,
              prompt: blanked,
              answer: entry.word,
              options: _shuffle([
                entry.word,
                ...distractors.map((d) => d.word),
              ], random),
              explanation: entry.exampleSentences.first.cn,
              word: _toWords([entry]).first,
            ),
          );
        }
      }

      // Spelling
      questions.add(
        QuizQuestion(
          id: '${entry.id}-spelling',
          type: QuizQuestionType.spelling,
          prompt: entry.definitions.isNotEmpty
              ? '${entry.definitions.first}（拼写）'
              : '拼写：${entry.word}',
          answer: entry.word,
          options: const [],
          explanation: entry.exampleSentences.isNotEmpty
              ? entry.exampleSentences.first.en
              : '',
          word: _toWords([entry]).first,
        ),
      );
    }
    return questions;
  }

  List<WordEntry> _pickDistractors(
    WordEntry target, {
    required List<WordEntry> allEntries,
    required int count,
    required Random random,
  }) {
    final candidates = allEntries.where((e) => e.id != target.id).toList();
    if (candidates.isEmpty) return [];
    candidates.shuffle(random);
    return candidates.take(count).toList();
  }

  List<String> _shuffle(List<String> items, Random random) {
    final copy = [...items];
    copy.shuffle(random);
    return copy;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
