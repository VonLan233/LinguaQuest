// test/data/asset_loader_cache_test.dart
//
// §7 (P4e): the bundled asset loaders memoize their load future; clearCache()
// must drop it so the next read re-reads from the bundle. Verified with a
// counting AssetBundle.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/article_asset_loader.dart';
import 'package:linguaquest/data/wordbook_asset_loader.dart';

/// Serves `lib/assets/data/*.json` from disk and counts every load() call.
class _CountingAssetBundle extends CachingAssetBundle {
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    final file = File(key);
    if (!file.existsSync()) {
      throw FlutterError('Asset not found: $key');
    }
    final bytes = await file.readAsBytes();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WordBookAssetLoader memoizes until clearCache re-reads', () async {
    final bundle = _CountingAssetBundle();
    final loader = WordBookAssetLoader(bundle: bundle);

    final first = await loader.loadWordBooks();
    final afterFirst = bundle.loadCount;
    expect(afterFirst, greaterThan(0));
    expect(first, isNotEmpty);

    // Second read is served from the memoized future — no new bundle loads.
    await loader.loadWordBooks();
    expect(bundle.loadCount, afterFirst);

    // clearCache drops the future → next read re-reads from the bundle.
    loader.clearCache();
    final reloaded = await loader.loadWordBooks();
    expect(bundle.loadCount, greaterThan(afterFirst));
    expect(reloaded.length, first.length);
  });

  test('ArticleAssetLoader memoizes until clearCache re-reads', () async {
    final bundle = _CountingAssetBundle();
    final loader = ArticleAssetLoader(bundle: bundle);

    final first = await loader.loadArticles();
    final afterFirst = bundle.loadCount;
    expect(afterFirst, greaterThan(0));
    expect(first, isNotEmpty);

    await loader.loadArticles();
    expect(bundle.loadCount, afterFirst);

    loader.clearCache();
    final reloaded = await loader.loadArticles();
    expect(bundle.loadCount, greaterThan(afterFirst));
    expect(reloaded.length, first.length);
  });
}
