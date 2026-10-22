import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/lesson.dart';

/// A downloaded book is durable content, separate from disposable memory caches.
class OfflineWordbookStore {
  static const _prefix = 'linguaquest.downloaded.wordbook.';

  Future<List<WordBook>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final books = <WordBook>[];
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      try {
        final json = jsonDecode(prefs.getString(key)!);
        final book = WordBook.fromJson(Map<String, dynamic>.from(json as Map));
        validate(book, key.substring(_prefix.length));
        books.add(book);
      } catch (_) {
        // Preserve malformed data for recovery; a bundled copy still works.
      }
    }
    return books;
  }

  Future<void> save(WordBook book, String expectedId) async {
    validate(book, expectedId);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      '$_prefix${book.id}',
      jsonEncode(book.toJson()),
    )) {
      throw StateError('Unable to save wordbook');
    }
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }

  static void validate(WordBook book, String expectedId) {
    if (book.id != expectedId ||
        book.words.isEmpty ||
        !{'zh', 'ja', 'en', 'es', 'fr', 'ms'}.contains(book.language) ||
        book.words.any(
          (w) =>
              w.id.isEmpty ||
              w.word.trim().isEmpty ||
              w.definitionsFor('en').isEmpty,
        ) ||
        book.words.map((w) => w.id).toSet().length != book.words.length ||
        book.words.length != book.includedWords ||
        book.wordIds
            .toSet()
            .difference(book.words.map((w) => w.id).toSet())
            .isNotEmpty) {
      throw const FormatException('Invalid or incomplete wordbook download');
    }
  }
}
