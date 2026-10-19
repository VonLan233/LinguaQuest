import '../../data/models/lesson.dart';
import 'text_language.dart';

/// Only advertise languages with real definitions for every entry, excluding
/// the generic placeholders returned by definitionsFor on legacy content.
List<String> wordbookExplanationLanguages(WordBook book) => [
  for (final code in ['zh', 'ja', 'en'])
    if (book.words.isNotEmpty &&
        book.words.every((word) {
          if (word.localizedDefinitions[code]?.any(
                (s) => s.trim().isNotEmpty,
              ) ??
              false) {
            return true;
          }
          if (code == 'en') {
            return word.englishDefinitions.any(
              (s) => s.trim().isNotEmpty && !containsCjkText(s),
            );
          }
          if (code == 'zh') {
            return word.definitions.any(containsCjkText) ||
                containsCjkText(word.meaning);
          }
          return false;
        }))
      code,
];
