import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/data/repositories/article_repository.dart';

/// In-memory [ArticleRepository] for widget tests. Filters in memory and records
/// saved progress + results for assertions.
class FakeArticleRepository implements ArticleRepository {
  FakeArticleRepository(this._articles);

  final List<Article> _articles;

  final List<ReadingProgress> savedProgress = [];
  final List<ReadingResult> savedResults = [];

  /// Seeded resume progress, keyed by articleId, returned by lookups.
  final Map<String, ReadingProgress> seededProgress = {};

  @override
  Future<List<Article>> listArticles({
    String? language,
    String? level,
    String? theme,
  }) async {
    return _articles.where((a) {
      if (language != null && language.isNotEmpty && a.language != language) {
        return false;
      }
      if (level != null && level.isNotEmpty && a.level != level) return false;
      if (theme != null && theme.isNotEmpty && a.theme != theme) return false;
      return true;
    }).toList();
  }

  @override
  Future<Article?> getArticle(String id) async {
    for (final a in _articles) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<ReadingProgress?> loadProgress(
    String uid,
    String scope,
    String articleId,
  ) async =>
      seededProgress[articleId];

  @override
  Future<List<ReadingProgress>> loadProgressForScope(
    String uid,
    String scope,
  ) async =>
      seededProgress.values.toList();

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    savedProgress.add(progress);
  }

  @override
  Future<void> recordComprehensionResult(ReadingResult result) async {
    savedResults.add(result);
  }

  @override
  Future<List<ReadingResult>> loadResults(String uid, String scope) async =>
      savedResults;

  @override
  Future<void> clearOfflineCache() async {}
}
