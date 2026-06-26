import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../article_asset_loader.dart';
import '../models/article.dart';
import '../remote/api_client.dart';

/// Per-article reading progress, scoped by `language::level`.
class ReadingProgress {
  const ReadingProgress({
    required this.uid,
    required this.scope,
    required this.articleId,
    this.lastParagraphIndex = 0,
    this.completed = false,
    required this.updatedAt,
  });

  final String uid;

  /// `language::level` token (see `progressScope`).
  final String scope;
  final String articleId;
  final int lastParagraphIndex;
  final bool completed;
  final DateTime updatedAt;

  ReadingProgress copyWith({
    int? lastParagraphIndex,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      uid: uid,
      scope: scope,
      articleId: articleId,
      lastParagraphIndex: lastParagraphIndex ?? this.lastParagraphIndex,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      uid: json['uid']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      articleId: json['articleId']?.toString() ?? '',
      lastParagraphIndex: _int(json['lastParagraphIndex']),
      completed: json['completed'] == true,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'scope': scope,
    'articleId': articleId,
    'lastParagraphIndex': lastParagraphIndex,
    'completed': completed,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// A graded reading-comprehension result (analytics feed).
class ReadingResult {
  const ReadingResult({
    required this.uid,
    required this.scope,
    required this.articleId,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.theme = '',
    this.perKindCorrect = const {},
    required this.createdAt,
  });

  final String uid;
  final String scope;
  final String articleId;
  final int totalQuestions;
  final int correctAnswers;
  final String theme;

  /// comprehensionKind → correct count.
  final Map<String, int> perKindCorrect;
  final DateTime createdAt;

  factory ReadingResult.fromJson(Map<String, dynamic> json) {
    final perKind = <String, int>{};
    final rawPerKind = json['perKindCorrect'];
    if (rawPerKind is Map) {
      rawPerKind.forEach((key, value) {
        perKind[key.toString()] = _int(value);
      });
    }
    return ReadingResult(
      uid: json['uid']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      articleId: json['articleId']?.toString() ?? '',
      totalQuestions: _int(json['totalQuestions']),
      correctAnswers: _int(json['correctAnswers']),
      theme: json['theme']?.toString() ?? '',
      perKindCorrect: perKind,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'scope': scope,
    'articleId': articleId,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'theme': theme,
    'perKindCorrect': perKindCorrect,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Repository for reading articles + reading progress/results.
///
/// Articles stay client-bundled (offline, like wordbooks). Progress/results are
/// persisted locally in Mock mode and may sync to the server in Api mode.
abstract class ArticleRepository {
  Future<List<Article>> listArticles({
    String? language,
    String? level,
    String? theme,
  });

  Future<Article?> getArticle(String id);

  Future<ReadingProgress?> loadProgress(String uid, String scope, String articleId);

  Future<List<ReadingProgress>> loadProgressForScope(String uid, String scope);

  Future<void> saveProgress(ReadingProgress progress);

  Future<void> recordComprehensionResult(ReadingResult result);

  Future<List<ReadingResult>> loadResults(String uid, String scope);
}

/// Offline implementation: bundled articles via [ArticleAssetLoader] + local
/// SharedPreferences for reading progress/results, scoped per `language::level`.
class MockArticleRepository implements ArticleRepository {
  MockArticleRepository(this._loader);

  final ArticleAssetLoader _loader;

  static String _progressKey(String scope) =>
      'linguaquest.reading.progress.$scope';
  static String _resultsKey(String uid, String scope) =>
      'linguaquest.reading.results.$uid.$scope';

  @override
  Future<List<Article>> listArticles({
    String? language,
    String? level,
    String? theme,
  }) async {
    final all = await _loader.loadArticles();
    return all.where((a) {
      if (language != null && language.isNotEmpty && a.language != language) {
        return false;
      }
      if (level != null && level.isNotEmpty && a.level != level) {
        return false;
      }
      if (theme != null && theme.isNotEmpty && a.theme != theme) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Article?> getArticle(String id) async {
    final all = await _loader.loadArticles();
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<Map<String, ReadingProgress>> _readProgressMap(
    String uid,
    String scope,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey(scope));
    final result = <String, ReadingProgress>{};
    if (raw == null) return result;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value is Map) {
            final json = Map<String, dynamic>.from(value);
            json['uid'] = uid;
            json['scope'] = scope;
            json['articleId'] = key.toString();
            result[key.toString()] = ReadingProgress.fromJson(json);
          }
        });
      }
    } catch (_) {
      // ignore corrupt payloads
    }
    return result;
  }

  @override
  Future<ReadingProgress?> loadProgress(
    String uid,
    String scope,
    String articleId,
  ) async {
    final map = await _readProgressMap(uid, scope);
    return map[articleId];
  }

  @override
  Future<List<ReadingProgress>> loadProgressForScope(
    String uid,
    String scope,
  ) async {
    final map = await _readProgressMap(uid, scope);
    return map.values.toList();
  }

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readProgressMap(progress.uid, progress.scope);
    map[progress.articleId] = progress;
    final encoded = <String, dynamic>{};
    map.forEach((key, value) {
      encoded[key] = {
        'lastParagraphIndex': value.lastParagraphIndex,
        'completed': value.completed,
        'updatedAt': value.updatedAt.toIso8601String(),
      };
    });
    await prefs.setString(_progressKey(progress.scope), jsonEncode(encoded));
  }

  @override
  Future<void> recordComprehensionResult(ReadingResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _resultsKey(result.uid, result.scope);
    final raw = prefs.getString(key);
    final list = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) list.add(Map<String, dynamic>.from(item));
          }
        }
      } catch (_) {
        // ignore corrupt payloads
      }
    }
    list.add(result.toJson());
    await prefs.setString(key, jsonEncode(list));
  }

  @override
  Future<List<ReadingResult>> loadResults(String uid, String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_resultsKey(uid, scope));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => ReadingResult.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
      // ignore corrupt payloads
    }
    return const [];
  }
}

/// API implementation. Articles remain client-bundled (delegates to the same
/// [ArticleAssetLoader] to avoid divergence); progress/results sync to the
/// server. The server routes are additive (P3e); until they exist this falls
/// back to local persistence so the app keeps working.
class ApiArticleRepository implements ArticleRepository {
  ApiArticleRepository(this._client, ArticleAssetLoader loader)
    : _local = MockArticleRepository(loader);

  final ApiClient _client;
  final MockArticleRepository _local;

  @override
  Future<List<Article>> listArticles({
    String? language,
    String? level,
    String? theme,
  }) {
    // Articles are client-bundled even in API mode.
    return _local.listArticles(language: language, level: level, theme: theme);
  }

  @override
  Future<Article?> getArticle(String id) => _local.getArticle(id);

  @override
  Future<ReadingProgress?> loadProgress(
    String uid,
    String scope,
    String articleId,
  ) async {
    try {
      final parts = scope.split('::');
      final language = parts.isNotEmpty ? parts.first : '';
      final wordBookId = parts.length > 1 ? parts[1] : '';
      final response = await _client.dio.get<dynamic>(
        '/reading/progress',
        queryParameters: {
          'language': language,
          'wordBookId': wordBookId,
          'articleId': articleId,
        },
      );
      final data = response.data;
      if (data is Map) {
        final json = Map<String, dynamic>.from(data);
        json['uid'] = uid;
        json['scope'] = scope;
        json['articleId'] = articleId;
        return ReadingProgress.fromJson(json);
      }
      return null;
    } on DioException {
      return _local.loadProgress(uid, scope, articleId);
    }
  }

  @override
  Future<List<ReadingProgress>> loadProgressForScope(
    String uid,
    String scope,
  ) {
    // Progress-list aggregation is server-side P3e; fall back to local.
    return _local.loadProgressForScope(uid, scope);
  }

  @override
  Future<void> saveProgress(ReadingProgress progress) async {
    // Always persist locally so resume works offline.
    await _local.saveProgress(progress);
    try {
      final parts = progress.scope.split('::');
      final language = parts.isNotEmpty ? parts.first : '';
      final wordBookId = parts.length > 1 ? parts[1] : '';
      await _client.dio.put<dynamic>(
        '/reading/progress',
        data: {
          'language': language,
          'wordBookId': wordBookId,
          'articleId': progress.articleId,
          'lastIndex': progress.lastParagraphIndex,
          'completed': progress.completed,
        },
      );
    } on DioException {
      // server route may not exist yet (P3e); local copy is authoritative.
    }
  }

  @override
  Future<void> recordComprehensionResult(ReadingResult result) async {
    await _local.recordComprehensionResult(result);
    try {
      final parts = result.scope.split('::');
      final language = parts.isNotEmpty ? parts.first : '';
      final wordBookId = parts.length > 1 ? parts[1] : '';
      await _client.dio.post<dynamic>(
        '/reading/results',
        data: {
          'language': language,
          'wordBookId': wordBookId,
          'articleId': result.articleId,
          'total': result.totalQuestions,
          'correct': result.correctAnswers,
          'theme': result.theme,
          'perKind': result.perKindCorrect,
        },
      );
    } on DioException {
      // server route may not exist yet (P3e); local copy is authoritative.
    }
  }

  @override
  Future<List<ReadingResult>> loadResults(String uid, String scope) =>
      _local.loadResults(uid, scope);
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
