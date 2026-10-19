import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import 'text_language.dart';

/// Resolves a custom/review word's meaning for [languageCode], preferring the
/// per-language definition lists carried over from a source dictionary word.
///
/// When no stored definition exists for the language (e.g. manually-added
/// words), the original [CustomWord.meaning] is shown verbatim — we never
/// synthesize filler text. The 'ms' chain mirrors [Word.definitionsFor]:
/// Malay → English → meaning.
///
/// English/Malay candidates that still contain CJK characters are skipped:
/// some baked dictionary data carries auto-generated English "definitions"
/// that embed the Chinese gloss, which must not surface in a Latin-script UI.
String customWordMeaningFor(CustomWord word, String languageCode) {
  final normalizedLanguage = languageCode.toLowerCase();
  final localized = _firstNonEmpty(
    word.localizedDefinitions[normalizedLanguage] ?? [],
  );
  if (localized != null) return localized;
  if (normalizedLanguage == 'ja') {
    return _firstNonEmpty(word.englishDefinitions) ?? word.meaning;
  }
  final meaning = word.meaning.trim();
  final fallback = meaning.isEmpty ? word.word.trim() : meaning;

  if (normalizedLanguage == 'en') {
    return _firstLatin(word.englishDefinitions) ?? fallback;
  }
  if (normalizedLanguage == 'ms') {
    return _firstNonEmpty(word.malayDefinitions) ??
        _firstLatin(word.englishDefinitions) ??
        fallback;
  }
  // zh and any other locale.
  return _firstNonEmpty(word.definitions) ?? fallback;
}

String? _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? _firstLatin(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !containsCjkText(trimmed)) return trimmed;
  }
  return null;
}

Word wordFromCustomWord(CustomWord word) {
  final englishMeaning = customWordMeaningFor(word, 'en');
  final malayMeaning = customWordMeaningFor(word, 'ms');
  final chineseMeaning = customWordMeaningFor(word, 'zh');
  return Word(
    id: word.id,
    localizedDefinitions: word.localizedDefinitions,
    word: word.word,
    phonetic: '',
    meaning: chineseMeaning,
    definition: englishMeaning,
    partOfSpeech: 'word',
    exampleSentence: word.exampleSentence,
    exampleTranslation: '',
    imageCue: _initialCue(word.word),
    difficulty: word.difficulty,
    tags: [word.tag],
    definitions: [if (chineseMeaning.isNotEmpty) chineseMeaning],
    englishDefinitions: [if (englishMeaning.isNotEmpty) englishMeaning],
    malayDefinitions: [if (malayMeaning.isNotEmpty) malayMeaning],
  );
}

String _initialCue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}
