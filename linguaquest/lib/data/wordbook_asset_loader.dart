import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/lesson.dart';

class WordBookAssetLoader {
  WordBookAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _bookIds = [
    'beginner',
    'ielts',
    'toefl',
    'gre',
    'cet4',
    'cet6',
    'kaoyan',
  ];

  static List<WordBook>? _sharedCache;

  final AssetBundle _bundle;
  List<WordBook>? _cache;

  Future<List<WordBook>> loadWordBooks() async {
    final cached = _cache ?? _sharedCache;
    if (cached != null) return cached;

    final books = <WordBook>[];
    for (final bookId in _bookIds) {
      try {
        final raw = await _loadAssetString(bookId);
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          books.add(WordBook.fromJson(decoded));
        }
      } catch (_) {
        // Skip wordbooks that fail to load
      }
    }

    _sharedCache = List.unmodifiable(books);
    _cache = _sharedCache;
    return _cache!;
  }

  Future<String> _loadAssetString(String bookId) async {
    final data = await _bundle.load('lib/assets/data/wordbook_$bookId.json');
    return utf8.decode(Uint8List.sublistView(data));
  }
}
