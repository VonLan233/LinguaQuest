import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/article_asset_loader.dart';
import 'package:linguaquest/data/repositories/article_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An [AssetBundle] that serves `lib/assets/data/*.json` from the real
/// filesystem, so the loader can be exercised without a Flutter asset binding.
class _FileSystemAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
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

  final bundle = _FileSystemAssetBundle();

  group('ArticleAssetLoader', () {
    test('loads the seed articles for both bundled levels', () async {
      final articles = await ArticleAssetLoader(bundle: bundle).loadArticles();

      final zh = articles.where((a) => a.language == 'zh').toList();
      final ja = articles.where((a) => a.language == 'ja').toList();

      expect(zh.length, 3, reason: 'three Chinese hsk1 seed articles');
      expect(ja.length, 2, reason: 'two Japanese jlpt_n5 seed articles');
      expect(articles.length, 5);

      for (final a in zh) {
        expect(a.level, 'hsk1');
        expect(a.examLevel, 1);
      }
      for (final a in ja) {
        expect(a.level, 'jlpt_n5');
        expect(a.examLevel, 5);
      }

      // Every article: paragraphs with translation + >=2 comprehension questions.
      for (final a in articles) {
        expect(a.title.trim(), isNotEmpty, reason: '${a.id} has a title');
        expect(a.titleTranslation.trim(), isNotEmpty);
        expect(a.theme, isIn(['campus', 'life', 'travel']));
        expect(a.paragraphs.length, greaterThanOrEqualTo(3));
        for (final p in a.paragraphs) {
          expect(p.text.trim(), isNotEmpty, reason: '${a.id} paragraph has text');
          expect(p.translation.trim(), isNotEmpty,
              reason: '${a.id} paragraph has translation');
          expect(p.reading.trim(), isNotEmpty,
              reason: '${a.id} paragraph has a reading line');
        }
        expect(a.comprehension.length, greaterThanOrEqualTo(2),
            reason: '${a.id} has >=2 comprehension questions');
        for (final q in a.comprehension) {
          expect(q.prompt.trim(), isNotEmpty);
          expect(q.options.length, greaterThanOrEqualTo(2));
          expect(q.options, contains(q.answer),
              reason: '${q.id} answer is one of the options');
        }
        expect(a.vocab, isNotEmpty, reason: '${a.id} has vocab refs');
      }
    });

    test('Japanese articles carry romaji/kana readings', () async {
      final articles = await ArticleAssetLoader(bundle: bundle).loadArticles();
      final ja = articles.where((a) => a.language == 'ja');
      final romaji = RegExp(r'[a-z]');
      for (final a in ja) {
        for (final p in a.paragraphs) {
          expect(romaji.hasMatch(p.reading), isTrue,
              reason: '${a.id} reading should contain romaji/kana: ${p.reading}');
        }
      }
    });
  });

  group('MockArticleRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('listArticles filters by language + level', () async {
      final repo = MockArticleRepository(ArticleAssetLoader(bundle: bundle));

      final zhHsk1 = await repo.listArticles(language: 'zh', level: 'hsk1');
      expect(zhHsk1.length, 3);
      expect(zhHsk1.every((a) => a.language == 'zh' && a.level == 'hsk1'), isTrue);

      final jaN5 = await repo.listArticles(language: 'ja', level: 'jlpt_n5');
      expect(jaN5.length, 2);

      final none = await repo.listArticles(language: 'zh', level: 'hsk6');
      expect(none, isEmpty);

      final travel =
          await repo.listArticles(language: 'zh', level: 'hsk1', theme: 'travel');
      expect(travel.length, 1);
      expect(travel.first.theme, 'travel');
    });

    test('getArticle returns the right article by id', () async {
      final repo = MockArticleRepository(ArticleAssetLoader(bundle: bundle));
      final article = await repo.getArticle('ja_n5_travel_001');
      expect(article, isNotNull);
      expect(article!.language, 'ja');
      expect(article.theme, 'travel');
      expect(await repo.getArticle('does_not_exist'), isNull);
    });

    test('reading-progress save/load round-trips scoped per language::level',
        () async {
      final repo = MockArticleRepository(ArticleAssetLoader(bundle: bundle));
      final now = DateTime.parse('2026-06-27T10:00:00.000Z');

      await repo.saveProgress(ReadingProgress(
        uid: 'u1',
        scope: 'zh::hsk1',
        articleId: 'zh_hsk1_life_001',
        lastParagraphIndex: 2,
        completed: true,
        updatedAt: now,
      ));
      await repo.saveProgress(ReadingProgress(
        uid: 'u1',
        scope: 'ja::jlpt_n5',
        articleId: 'ja_n5_life_001',
        lastParagraphIndex: 1,
        completed: false,
        updatedAt: now,
      ));

      final loaded =
          await repo.loadProgress('u1', 'zh::hsk1', 'zh_hsk1_life_001');
      expect(loaded, isNotNull);
      expect(loaded!.lastParagraphIndex, 2);
      expect(loaded.completed, isTrue);

      // Sibling scope is isolated.
      final zhScope = await repo.loadProgressForScope('u1', 'zh::hsk1');
      expect(zhScope.length, 1);
      final jaScope = await repo.loadProgressForScope('u1', 'ja::jlpt_n5');
      expect(jaScope.length, 1);
      expect(jaScope.first.articleId, 'ja_n5_life_001');
      expect(jaScope.first.completed, isFalse);
    });

    test('comprehension result save/load round-trips per scope', () async {
      final repo = MockArticleRepository(ArticleAssetLoader(bundle: bundle));
      await repo.recordComprehensionResult(ReadingResult(
        uid: 'u1',
        scope: 'zh::hsk1',
        articleId: 'zh_hsk1_life_001',
        totalQuestions: 3,
        correctAnswers: 2,
        theme: 'life',
        perKindCorrect: const {'detail': 1, 'trueFalse': 1},
        createdAt: DateTime.parse('2026-06-27T11:00:00.000Z'),
      ));

      final results = await repo.loadResults('u1', 'zh::hsk1');
      expect(results.length, 1);
      expect(results.first.totalQuestions, 3);
      expect(results.first.correctAnswers, 2);
      expect(results.first.theme, 'life');
      expect(results.first.perKindCorrect['detail'], 1);

      // Other scope is empty.
      expect(await repo.loadResults('u1', 'ja::jlpt_n5'), isEmpty);
    });
  });
}
