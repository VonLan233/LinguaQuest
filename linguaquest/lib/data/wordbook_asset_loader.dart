import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/lesson.dart';

class WordBookAssetLoader {
  WordBookAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _bookIds = [
    'beginner',
    'cet4',
    'cet6',
    'ielts',
    'toefl',
    'gre',
    'kaoyan',
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

  Future<String> _loadAssetString(String bookId) async {
    final data = await _bundle.load('lib/assets/data/wordbook_$bookId.json');
    return utf8.decode(Uint8List.sublistView(data));
  }
}
