import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/lesson.dart';

class WordBookAssetLoader {
  WordBookAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _bookIds = [
    'hsk1',
    'hsk2',
    'hsk3',
    'hsk4',
    'hsk5',
    'hsk6',
    'jlpt_n5',
    'jlpt_n4',
    'jlpt_n3',
    'jlpt_n2',
    'jlpt_n1',
    'en_basic',
    'es_basic',
    'fr_basic',
    'ms_basic',
  ];

  final AssetBundle _bundle;
  Future<List<WordBook>>? _loadFuture;

  Future<List<WordBook>> loadWordBooks() async {
    _loadFuture ??= () async {
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
      return List<WordBook>.unmodifiable(books);
    }();

    return _loadFuture!;
  }

  /// Drops the memoized load future so the next [loadWordBooks] re-reads the
  /// bundled assets from disk (used by the manual "Refresh content" action).
  void clearCache() {
    _loadFuture = null;
  }

  Future<String> _loadAssetString(String bookId) async {
    final data = await _bundle.load('lib/assets/data/wordbook_$bookId.json');
    return utf8.decode(Uint8List.sublistView(data));
  }
}
