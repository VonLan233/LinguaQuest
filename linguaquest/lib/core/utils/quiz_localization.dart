import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

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
  return translations[value.trim()] ?? value;
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

String localizedQuizPrompt(QuizQuestion question, AppLocalizations l10n) {
  return switch (question.type) {
    QuizQuestionType.chineseChoice => l10n.trainingPromptChineseChoice(
      _promptDetail(question.prompt),
    ),
    QuizQuestionType.contextChoice => l10n.trainingPromptContextChoice(
      _promptDetail(question.prompt),
    ),
    QuizQuestionType.spelling => l10n.trainingPromptChineseSpelling(
      _promptDetail(question.prompt),
    ),
    QuizQuestionType.meaningChoice ||
    QuizQuestionType.imageChoice => l10n.trainingPromptMeaningChoice(
      _quotedValue(question.prompt) ?? question.word.word,
    ),
    QuizQuestionType.listeningWordChoice => question.prompt,
    QuizQuestionType.listeningMeaningChoice => question.prompt,
  };
}

String localizedQuizExplanation(QuizQuestion question, AppLocalizations l10n) {
  final localeName = l10n.localeName;
  final meaning = question.word.primaryDefinitionFor(localeName);
  return switch (question.type) {
    QuizQuestionType.chineseChoice || QuizQuestionType.listeningWordChoice =>
      l10n.trainingExplanationChineseChoice(meaning, question.word.word),
    QuizQuestionType.spelling => l10n.trainingExplanationSpelling(
      question.word.word,
      question.word.exampleSentence,
    ),
    QuizQuestionType.meaningChoice ||
    QuizQuestionType.contextChoice ||
    QuizQuestionType.imageChoice ||
    QuizQuestionType.listeningMeaningChoice =>
      l10n.trainingExplanationMeaningChoice(question.word.word, meaning),
  };
}

String _promptDetail(String prompt) {
  final colonIndex = prompt.lastIndexOf('：');
  if (colonIndex >= 0 && colonIndex < prompt.length - 1) {
    return prompt.substring(colonIndex + 1).trim();
  }
  final asciiColonIndex = prompt.lastIndexOf(':');
  if (asciiColonIndex >= 0 && asciiColonIndex < prompt.length - 1) {
    return prompt.substring(asciiColonIndex + 1).trim();
  }
  return prompt.trim();
}

String? _quotedValue(String prompt) {
  final left = prompt.indexOf('“');
  final right = prompt.indexOf('”', left + 1);
  if (left >= 0 && right > left) {
    return prompt.substring(left + 1, right).trim();
  }
  final asciiLeft = prompt.indexOf('"');
  final asciiRight = prompt.indexOf('"', asciiLeft + 1);
  if (asciiLeft >= 0 && asciiRight > asciiLeft) {
    return prompt.substring(asciiLeft + 1, asciiRight).trim();
  }
  return null;
}
