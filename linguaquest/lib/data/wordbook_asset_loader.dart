import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/lesson.dart';

class WordBookAssetLoader {
  WordBookAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _bookIds = [
    'beginner',
    'ielts',
    'toefl',
    'gre',
  ];

  static List<WordBook>? _sharedCache;
  static Future<List<WordBook>>? _sharedLoadFuture;

  final AssetBundle _bundle;
  List<WordBook>? _cache;

  Future<List<WordBook>> loadWordBooks() async {
    final cached = _cache ?? _sharedCache;
    if (cached != null) return cached;

    _sharedLoadFuture ??= () async {
      final books = <WordBook>[];
      for (final bookId in _bookIds) {
        try {
          final raw = await _loadAssetString(bookId);
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            books.add(WordBook.fromJson(decoded));
          }
        } catch (e, stackTrace) {
          debugPrint('Failed to load wordbook $bookId: $e\n$stackTrace');
        }
      }
      _sharedCache = List.unmodifiable(books);
      return _sharedCache!;
    }();

    _cache = await _sharedLoadFuture;
    return _cache!;
  }

  Future<String> _loadAssetString(String bookId) async {
    final data = await _bundle.load('lib/assets/data/wordbook_$bookId.json');
    return utf8.decode(Uint8List.sublistView(data));
  }
}
