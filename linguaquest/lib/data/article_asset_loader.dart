import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/article.dart';

/// Loads bundled reading articles from `lib/assets/data/articles_<level>.json`.
///
/// Mirrors [WordBookAssetLoader]: one file per wordbook level, loaded lazily with
/// per-file try/catch, cached behind a single future. Each file has the shape
/// `{ "level": "...", "language": "...", "articles": [ Article… ] }`.
class ArticleAssetLoader {
  ArticleAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Levels that currently have a bundled `articles_<level>.json` file.
  /// Add a level here (and register the asset in pubspec.yaml) when shipping
  /// content for it.
  static const _levelIds = <String>[
    'hsk1',
    'jlpt_n5',
  ];

  final AssetBundle _bundle;
  Future<List<Article>>? _loadFuture;

  Future<List<Article>> loadArticles() async {
    _loadFuture ??= () async {
      final articles = <Article>[];
      for (final levelId in _levelIds) {
        try {
          final raw = await _loadAssetString(levelId);
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final fileLevel = decoded['level']?.toString();
            final fileLanguage = decoded['language']?.toString();
            final list = decoded['articles'];
            if (list is List) {
              for (final item in list) {
                if (item is Map) {
                  final json = Map<String, dynamic>.from(item);
                  // Inherit file-level defaults when an article omits them.
                  if (fileLevel != null &&
                      (json['level'] == null ||
                          json['level'].toString().isEmpty)) {
                    json['level'] = fileLevel;
                  }
                  if (fileLanguage != null &&
                      (json['language'] == null ||
                          json['language'].toString().isEmpty)) {
                    json['language'] = fileLanguage;
                  }
                  articles.add(Article.fromJson(json));
                }
              }
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Failed to load articles $levelId: $e\n$stackTrace');
        }
      }
      return List<Article>.unmodifiable(articles);
    }();

    return _loadFuture!;
  }

  Future<String> _loadAssetString(String levelId) async {
    final data = await _bundle.load('lib/assets/data/articles_$levelId.json');
    return utf8.decode(Uint8List.sublistView(data));
  }
}
