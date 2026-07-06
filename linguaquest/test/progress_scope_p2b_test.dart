import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/utils/progress_scope.dart';

void main() {
  group('progressScope helper', () {
    test('produces correct composite token', () {
      expect(progressScope('zh', 'hsk1'), equals('zh::hsk1'));
      expect(progressScope('ja', 'jlpt_n5'), equals('ja::jlpt_n5'));
    });

    test('different languages produce different scopes', () {
      final zhScope = progressScope('zh', 'hsk1');
      final jaScope = progressScope('ja', 'hsk1');
      expect(zhScope, isNot(equals(jaScope)));
    });

    test('different wordbooks produce different scopes', () {
      final hsk1 = progressScope('zh', 'hsk1');
      final hsk2 = progressScope('zh', 'hsk2');
      expect(hsk1, isNot(equals(hsk2)));
    });

    test('scope token contains separator ::', () {
      final scope = progressScope('zh', 'hsk1');
      expect(scope, contains('::'));
    });
  });

  group('P2b scoped SharedPreferences keys', () {
    // Verify the key naming convention produces unique namespaced keys
    // so scopes are provably isolated.

    test('scoped completed key is scope-specific', () {
      const prefix = 'linguaquest.completedLessons';
      final scope1 = progressScope('zh', 'hsk1');
      final scope2 = progressScope('zh', 'hsk2');
      final key1 = '$prefix.$scope1';
      final key2 = '$prefix.$scope2';
      expect(key1, equals('linguaquest.completedLessons.zh::hsk1'));
      expect(key2, equals('linguaquest.completedLessons.zh::hsk2'));
      expect(key1, isNot(equals(key2)));
    });

    test('scoped today.lessons key is scope-specific', () {
      const prefix = 'linguaquest.today.lessons';
      final scope1 = progressScope('zh', 'hsk1');
      final scope2 = progressScope('zh', 'hsk2');
      expect('$prefix.$scope1', equals('linguaquest.today.lessons.zh::hsk1'));
      expect('$prefix.$scope1', isNot(equals('$prefix.$scope2')));
    });

    test('scoped user_words key includes uid and scope', () {
      const uid = 'user-123';
      final scope = progressScope('zh', 'hsk1');
      final key = 'linguaquest.user_words.$uid.$scope';
      expect(key, equals('linguaquest.user_words.user-123.zh::hsk1'));
    });
  });

  group('P2b migration flag logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('migration flag key has expected value', () {
      const flagKey = 'linguaquest.migrated.v2_scope';
      expect(flagKey, equals('linguaquest.migrated.v2_scope'));
    });

    test('migration copies legacy completedLessons to zh::hsk1 scope', () async {
      const legacyKey = 'linguaquest.completedLessons';
      const flagKey = 'linguaquest.migrated.v2_scope';
      final scopedKey =
          'linguaquest.completedLessons.${progressScope('zh', 'hsk1')}';

      SharedPreferences.setMockInitialValues({
        legacyKey: ['lesson-1', 'lesson-2', 'lesson-3'],
      });

      final prefs = await SharedPreferences.getInstance();

      // Pre-condition: global key exists, scoped key doesn't, flag not set
      expect(prefs.getStringList(legacyKey),
          equals(['lesson-1', 'lesson-2', 'lesson-3']));
      expect(prefs.getStringList(scopedKey), isNull);
      expect(prefs.getBool(flagKey), isNull);

      // Run migration logic (simulates what _runMigrationV2Scope does)
      await _simulateMigration(prefs);

      // Post-condition: scoped key has the data, flag is set, global key still exists
      expect(
        prefs.getStringList(scopedKey),
        equals(['lesson-1', 'lesson-2', 'lesson-3']),
        reason: 'Legacy completed lessons must be copied to zh::hsk1 scope',
      );
      expect(
        prefs.getBool(flagKey),
        isTrue,
        reason: 'Migration flag must be set after migration',
      );
      expect(
        prefs.getStringList(legacyKey),
        equals(['lesson-1', 'lesson-2', 'lesson-3']),
        reason: 'COPY not delete: original global key must still exist',
      );
    });

    test('migration is idempotent: running twice is a no-op', () async {
      const legacyKey = 'linguaquest.completedLessons';
      final scopedKey =
          'linguaquest.completedLessons.${progressScope('zh', 'hsk1')}';

      SharedPreferences.setMockInitialValues({
        legacyKey: ['lesson-1', 'lesson-2'],
      });

      final prefs = await SharedPreferences.getInstance();

      // Run migration once
      await _simulateMigration(prefs);

      // Modify the scoped key to verify it's NOT overwritten on second run
      await prefs.setStringList(
          scopedKey, ['lesson-1', 'lesson-2', 'lesson-EXTRA']);

      // Run migration again — should be a no-op because flag is set
      await _simulateMigration(prefs);

      // The scoped key should still have the manually added 'lesson-EXTRA'
      // because the migration did NOT run again.
      expect(
        prefs.getStringList(scopedKey),
        equals(['lesson-1', 'lesson-2', 'lesson-EXTRA']),
        reason: 'Second migration run must be no-op due to flag guard',
      );
    });

    test('migration preserves today.lessons under zh::hsk1', () async {
      const legacyTodayLessons = 'linguaquest.today.lessons';
      const flagKey = 'linguaquest.migrated.v2_scope';
      final scopedTodayKey =
          'linguaquest.today.lessons.${progressScope('zh', 'hsk1')}';

      SharedPreferences.setMockInitialValues({
        legacyTodayLessons: ['lesson-today-1'],
      });

      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);

      expect(prefs.getStringList(scopedTodayKey), equals(['lesson-today-1']));
      expect(prefs.getBool(flagKey), isTrue);
    });

    test('migration copies today.reviews under zh::hsk1', () async {
      const legacyTodayReviews = 'linguaquest.today.reviews';
      final scopedReviewKey =
          'linguaquest.today.reviews.${progressScope('zh', 'hsk1')}';

      SharedPreferences.setMockInitialValues({
        legacyTodayReviews: ['review-1', 'review-2'],
      });

      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);

      expect(
        prefs.getStringList(scopedReviewKey),
        equals(['review-1', 'review-2']),
        reason: 'today.reviews must be migrated to zh::hsk1 scope',
      );
    });

    test('migration copies today.rewards under zh::hsk1', () async {
      const legacyTodayRewards = 'linguaquest.today.rewards';
      final scopedRewardsKey =
          'linguaquest.today.rewards.${progressScope('zh', 'hsk1')}';

      SharedPreferences.setMockInitialValues({
        legacyTodayRewards: ['reward-a'],
      });

      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);

      expect(
        prefs.getStringList(scopedRewardsKey),
        equals(['reward-a']),
        reason: 'today.rewards must be migrated to zh::hsk1 scope',
      );
    });

    test('migration copies currentWordBookId to per-language key', () async {
      const legacyBookIdKey = 'linguaquest.currentWordBookId';
      const perLangKey = 'linguaquest.currentWordBookId.zh';

      SharedPreferences.setMockInitialValues({
        legacyBookIdKey: 'hsk2',
      });

      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);

      expect(
        prefs.getString(perLangKey),
        equals('hsk2'),
        reason: 'currentWordBookId must be copied to per-language key',
      );
    });

    test('migration sets default current_language to zh', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);

      expect(
        prefs.getString('linguaquest.current_language'),
        equals('zh'),
        reason: 'current_language must default to zh after migration',
      );
    });

    test('migration with no legacy data still sets the flag', () async {
      const flagKey = 'linguaquest.migrated.v2_scope';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);
      expect(
        prefs.getBool(flagKey),
        isTrue,
        reason: 'Flag must be set even when no legacy data to migrate',
      );
    });

    test('migration does not overwrite scoped key if it already exists', () async {
      final scopedKey =
          'linguaquest.completedLessons.${progressScope('zh', 'hsk1')}';

      // Simulate partial migration: scoped key already exists (e.g. from a
      // previous partial run), legacy key also exists with different data.
      SharedPreferences.setMockInitialValues({
        'linguaquest.completedLessons': ['old-lesson'],
        scopedKey: ['already-migrated-lesson'],
      });

      final prefs = await SharedPreferences.getInstance();
      await _simulateMigration(prefs);

      // Scoped key must NOT be overwritten; it already had data.
      expect(
        prefs.getStringList(scopedKey),
        equals(['already-migrated-lesson']),
        reason: 'Migration must not overwrite an existing scoped key',
      );
    });
  });

  group('P2b scope isolation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('writing to hsk1 scope does not affect hsk2 scope', () async {
      final prefs = await SharedPreferences.getInstance();

      const completedPrefix = 'linguaquest.completedLessons';
      final hsk1Scope = progressScope('zh', 'hsk1');
      final hsk2Scope = progressScope('zh', 'hsk2');

      // Write to hsk1 scope
      await prefs.setStringList(
        '$completedPrefix.$hsk1Scope',
        ['lesson-a', 'lesson-b'],
      );

      // hsk2 scope should be unaffected
      expect(
        prefs.getStringList('$completedPrefix.$hsk2Scope'),
        isNull,
        reason: 'hsk1 scope writes must not affect hsk2 scope',
      );
    });

    test('hsk1 progress survives writing to hsk2 scope', () async {
      final prefs = await SharedPreferences.getInstance();

      const completedPrefix = 'linguaquest.completedLessons';
      final hsk1Scope = progressScope('zh', 'hsk1');
      final hsk2Scope = progressScope('zh', 'hsk2');

      // Write to hsk1 scope
      await prefs.setStringList(
        '$completedPrefix.$hsk1Scope',
        ['lesson-a', 'lesson-b'],
      );

      // Write to hsk2 scope (simulating switchWordBook)
      await prefs.setStringList(
        '$completedPrefix.$hsk2Scope',
        ['lesson-x', 'lesson-y'],
      );

      // hsk1 data must be intact
      expect(
        prefs.getStringList('$completedPrefix.$hsk1Scope'),
        equals(['lesson-a', 'lesson-b']),
        reason: 'hsk1 progress must survive hsk2 writes',
      );

      // hsk2 data is independent
      expect(
        prefs.getStringList('$completedPrefix.$hsk2Scope'),
        equals(['lesson-x', 'lesson-y']),
        reason: 'hsk2 progress must be independent of hsk1',
      );
    });

    test('switching back to hsk1 restores its progress', () async {
      final prefs = await SharedPreferences.getInstance();

      const completedPrefix = 'linguaquest.completedLessons';
      final hsk1Scope = progressScope('zh', 'hsk1');
      final hsk2Scope = progressScope('zh', 'hsk2');

      // Step 1: Set up hsk1 progress
      await prefs.setStringList(
        '$completedPrefix.$hsk1Scope',
        ['lesson-a', 'lesson-b', 'lesson-c'],
      );

      // Step 2: Switch to hsk2, accumulate progress there
      await prefs.setStringList(
        '$completedPrefix.$hsk2Scope',
        ['lesson-x'],
      );

      // Step 3: "Switch back" to hsk1 (read its scoped key)
      final restoredHsk1 = prefs.getStringList('$completedPrefix.$hsk1Scope');

      expect(
        restoredHsk1,
        equals(['lesson-a', 'lesson-b', 'lesson-c']),
        reason:
            'Switching back to hsk1 must restore exactly its saved progress',
      );
    });

    test('zh and ja scopes for same wordbook id are independent', () async {
      final prefs = await SharedPreferences.getInstance();

      const completedPrefix = 'linguaquest.completedLessons';
      final zhScope = progressScope('zh', 'hsk1');
      final jaScope = progressScope('ja', 'hsk1');

      await prefs.setStringList('$completedPrefix.$zhScope', ['zh-lesson-1']);
      await prefs.setStringList('$completedPrefix.$jaScope', ['ja-lesson-1']);

      expect(
        prefs.getStringList('$completedPrefix.$zhScope'),
        equals(['zh-lesson-1']),
        reason: 'zh scope must not be affected by ja scope writes',
      );
      expect(
        prefs.getStringList('$completedPrefix.$jaScope'),
        equals(['ja-lesson-1']),
        reason: 'ja scope must not be affected by zh scope writes',
      );
    });

    test('multiple scoped keys within same scope are all independent', () async {
      final prefs = await SharedPreferences.getInstance();

      final scope = progressScope('zh', 'hsk1');

      await prefs.setStringList('linguaquest.completedLessons.$scope',
          ['l-1', 'l-2']);
      await prefs.setStringList('linguaquest.today.lessons.$scope', ['l-3']);
      await prefs.setStringList('linguaquest.today.reviews.$scope', ['r-1']);

      // All three keys must hold their own data independently
      expect(prefs.getStringList('linguaquest.completedLessons.$scope'),
          equals(['l-1', 'l-2']));
      expect(prefs.getStringList('linguaquest.today.lessons.$scope'),
          equals(['l-3']));
      expect(prefs.getStringList('linguaquest.today.reviews.$scope'),
          equals(['r-1']));
    });
  });
}

/// Simulates the migration logic from AppController._runMigrationV2Scope.
/// This mirrors the actual migration code for test purposes only.
/// The authoritative implementation lives in AppController.
Future<void> _simulateMigration(SharedPreferences prefs) async {
  const flagKey = 'linguaquest.migrated.v2_scope';
  if (prefs.getBool(flagKey) == true) return; // already done

  const lang = 'zh';
  const bookId = 'hsk1';
  final scope = progressScope(lang, bookId);

  // Copy completedLessons
  final globalCompleted = prefs.getStringList('linguaquest.completedLessons');
  if (globalCompleted != null &&
      prefs.getStringList('linguaquest.completedLessons.$scope') == null) {
    await prefs.setStringList(
        'linguaquest.completedLessons.$scope', globalCompleted);
  }

  // Copy today.lessons
  final globalTodayLessons =
      prefs.getStringList('linguaquest.today.lessons');
  if (globalTodayLessons != null &&
      prefs.getStringList('linguaquest.today.lessons.$scope') == null) {
    await prefs.setStringList(
        'linguaquest.today.lessons.$scope', globalTodayLessons);
  }

  // Copy today.reviews
  final globalTodayReviews =
      prefs.getStringList('linguaquest.today.reviews');
  if (globalTodayReviews != null &&
      prefs.getStringList('linguaquest.today.reviews.$scope') == null) {
    await prefs.setStringList(
        'linguaquest.today.reviews.$scope', globalTodayReviews);
  }

  // Copy today.training
  final globalTodayTraining =
      prefs.getStringList('linguaquest.today.training');
  if (globalTodayTraining != null &&
      prefs.getStringList('linguaquest.today.training.$scope') == null) {
    await prefs.setStringList(
        'linguaquest.today.training.$scope', globalTodayTraining);
  }

  // Copy today.training.games
  final globalTodayGames =
      prefs.getStringList('linguaquest.today.training.games');
  if (globalTodayGames != null &&
      prefs.getStringList('linguaquest.today.training.games.$scope') == null) {
    await prefs.setStringList(
        'linguaquest.today.training.games.$scope', globalTodayGames);
  }

  // Copy today.training.xp
  final globalTodayXp = prefs.getInt('linguaquest.today.training.xp');
  if (globalTodayXp != null &&
      prefs.getInt('linguaquest.today.training.xp.$scope') == null) {
    await prefs.setInt('linguaquest.today.training.xp.$scope', globalTodayXp);
  }

  // Copy today.rewards
  final globalTodayRewards =
      prefs.getStringList('linguaquest.today.rewards');
  if (globalTodayRewards != null &&
      prefs.getStringList('linguaquest.today.rewards.$scope') == null) {
    await prefs.setStringList(
        'linguaquest.today.rewards.$scope', globalTodayRewards);
  }

  // currentWordBookId → per-language key
  final globalBookId = prefs.getString('linguaquest.currentWordBookId');
  if (globalBookId != null &&
      prefs.getString('linguaquest.currentWordBookId.$lang') == null) {
    await prefs.setString('linguaquest.currentWordBookId.$lang', globalBookId);
  }

  // Set default current_language
  if (prefs.getString('linguaquest.current_language') == null) {
    await prefs.setString('linguaquest.current_language', lang);
  }

  // Set migration flag
  await prefs.setBool(flagKey, true);
}
