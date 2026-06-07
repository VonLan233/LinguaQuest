import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/lesson.dart';

class WordBookAssetLoader {
  WordBookAssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'lib/assets/data/wordbooks_p0.json';
  static List<WordBook>? _sharedCache;

  final AssetBundle _bundle;
  List<WordBook>? _cache;

  Future<List<WordBook>> loadWordBooks() async {
    final cached = _cache ?? _sharedCache;
    if (cached != null) return cached;
    final raw = await _loadAssetString();
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('wordbooks_p0.json must be a list');
    }
    final books = decoded.whereType<Map>().map((item) {
      return WordBook.fromJson(Map<String, dynamic>.from(item));
    }).toList();
    _sharedCache = List.unmodifiable(books);
    _cache = _sharedCache;
    return _cache!;
  }

  Future<String> _loadAssetString() async {
    final data = await _bundle.load(assetPath);
    return utf8.decode(Uint8List.sublistView(data));
  }
}
