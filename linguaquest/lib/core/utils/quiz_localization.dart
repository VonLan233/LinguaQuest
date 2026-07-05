import '../../data/models/lesson.dart';

/// Whether a quiz [type]'s options/answer are word MEANINGS (vs the English
/// word itself). Only meaning-based options need locale resolution; word-answer
/// types (chineseChoice, listeningWordChoice, spelling) already show English.
bool quizOptionsAreMeanings(QuizQuestionType type) {
  switch (type) {
    case QuizQuestionType.meaningChoice:
    case QuizQuestionType.contextChoice:
    case QuizQuestionType.imageChoice:
    case QuizQuestionType.listeningMeaningChoice:
      return true;
    case QuizQuestionType.chineseChoice:
    case QuizQuestionType.listeningWordChoice:
    case QuizQuestionType.spelling:
    // 新题型：选项为英文单词本身，不需要释义本地化
    case QuizQuestionType.sentenceCloze:
    case QuizQuestionType.confusableChoice:
    case QuizQuestionType.collocationChoice:
    case QuizQuestionType.derivativeChoice:
      return false;
  }
}

/// Builds a lookup from a word's canonical (Chinese) meaning to its meaning
/// localized for [languageCode], using every word in [pool]. The canonical key
/// matches how options are baked at generation time (`word.meaning`, i.e. the
/// first Chinese definition), so options/answers can be resolved at render time.
Map<String, String> buildMeaningTranslations(
  Iterable<Word> pool,
  String languageCode,
) {
  final map = <String, String>{};
  for (final word in pool) {
    final canonical = word.meaning.trim();
    if (canonical.isEmpty) continue;
    final localized = word.primaryDefinitionFor(languageCode).trim();
    if (localized.isEmpty) continue;
    map.putIfAbsent(canonical, () => localized);
  }
  return map;
}

/// Translates a single baked meaning [value] (a Chinese meaning string) to
/// [languageCode] using [translations]; returns the original when no mapping
/// exists so nothing is ever dropped.
String localizeMeaning(String value, Map<String, String> translations) {
  return translations[value.trim()] ?? value.trim();
}

/// Returns a copy of [question] with its `options` and `answer` resolved to
/// [languageCode], using the meanings carried by the words in [pool].
///
/// For 'zh' (the default locale) the resolved strings equal the originals, so
/// behaviour is unchanged. For word-answer question types, the question is
/// returned untouched. Because both the displayed options AND the answer are
/// mapped through the SAME translation table, the user still taps the option
/// that matches the (now-localized) answer, so correctness checks that compare
/// the tapped option against `question.answer` keep working.
QuizQuestion localizeQuizQuestion(
  QuizQuestion question,
  Iterable<Word> pool,
  String languageCode,
) {
  if (languageCode == 'zh') return question;
  if (!quizOptionsAreMeanings(question.type)) return question;

  final translations = buildMeaningTranslations(pool, languageCode);
  if (translations.isEmpty) return question;

  final localizedOptions = [
    for (final option in question.options)
      localizeMeaning(option, translations),
  ];
  final localizedAnswer = localizeMeaning(question.answer, translations);

  return QuizQuestion(
    id: question.id,
    type: question.type,
    prompt: question.prompt,
    answer: localizedAnswer,
    options: List.unmodifiable(localizedOptions),
    explanation: question.explanation,
    word: question.word,
  );
}
