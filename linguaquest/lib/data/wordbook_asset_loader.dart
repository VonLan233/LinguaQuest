import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/lesson.dart';

class WordBookAssetLoader {
  WordBookAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'lib/assets/data/wordbooks_p0.json';

  final AssetBundle _bundle;
  List<WordBook>? _cache;

  Future<List<WordBook>> loadWordBooks() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('wordbooks_p0.json must be a list');
    }
    final books = decoded.whereType<Map>().map((item) {
      return WordBook.fromJson(Map<String, dynamic>.from(item));
    }).toList();
    _cache = List.unmodifiable(books);
    return _cache!;
  }
}
