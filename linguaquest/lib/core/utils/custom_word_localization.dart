import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import 'text_language.dart';

String customWordMeaningFor(CustomWord word, String languageCode) {
  final normalizedLanguage = languageCode.toLowerCase();
  final meaning = word.meaning.trim();
  if (normalizedLanguage == 'zh' || normalizedLanguage.startsWith('zh_')) {
    return meaning.isEmpty ? word.word.trim() : meaning;
  }

  final note = word.note.trim();
  if (note.isNotEmpty && !containsCjkText(note)) return note;
  if (meaning.isNotEmpty && !containsCjkText(meaning)) return meaning;

  final fallbackWord = word.word.trim();
  if (fallbackWord.isNotEmpty && !containsCjkText(fallbackWord)) {
    if (normalizedLanguage == 'ms') {
      return 'Item kosa kata ulang kaji untuk $fallbackWord.';
    }
    return 'Review vocabulary item for $fallbackWord.';
  }

  if (normalizedLanguage == 'ms') return 'Item kosa kata ulang kaji.';
  return 'Review vocabulary item.';
}

Word wordFromCustomWord(CustomWord word) {
  final englishMeaning = customWordMeaningFor(word, 'en');
  final malayMeaning = customWordMeaningFor(word, 'ms');
  final chineseMeaning = customWordMeaningFor(word, 'zh');
  return Word(
    id: word.id,
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
