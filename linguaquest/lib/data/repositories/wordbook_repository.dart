import '../models/word_book.dart';
import '../models/word_entry.dart';

abstract class WordBookRepository {
  Future<List<WordBook>> listWordBooks();

  Future<WordBook?> getWordBook(String id);

  Future<List<WordEntry>> getWords(String bookId, {int? limit, int? offset});

  Future<WordEntry?> getWord(String wordId);

  Future<List<WordEntry>> searchWords(String query, {int limit = 20});
}
