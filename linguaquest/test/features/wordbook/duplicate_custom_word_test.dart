// Regression test for the duplicate custom-word bug (test task 5.3):
// adding the same word a second time silently returned success (`true`), so the
// UI showed "saved" again and the user got no signal the word already existed.
//
// After the fix, addCustomWord stays idempotent (never writes a duplicate) but
// distinguishes the two cases: a genuinely new add returns true; a duplicate
// returns false with a cleared errorMessage, letting the screen show an
// "already in wordbook" message instead of "saved".

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'addCustomWord signals duplicate on the second add (idempotent, no dup write)',
    () async {
      final now = DateTime(2026, 7, 5);
      final profile = UserProfile(
        uid: 'dup-word-user',
        name: 'Test',
        email: 'test@linguaquest.test',
        targetExam: 'HSK 1',
        level: 'Beginner',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );

      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appControllerProvider.notifier);
      await notifier.bootstrap();

      final firstAdd = await notifier.addCustomWord(
        word: 'context',
        meaning: '语境',
        exampleSentence: 'Context helps memory.',
        note: '',
        tag: 'study',
        difficulty: 'Medium',
      );
      expect(firstAdd, isTrue, reason: 'first add is a genuine new word');
      final countAfterFirst =
          container.read(appControllerProvider).customWords.length;

      final secondAdd = await notifier.addCustomWord(
        word: '  Context  ', // same word, different case/whitespace
        meaning: '语境',
        exampleSentence: 'Context helps memory.',
        note: '',
        tag: 'study',
        difficulty: 'Medium',
      );

      expect(
        secondAdd,
        isFalse,
        reason: 'duplicate add must not report success',
      );
      expect(
        container.read(appControllerProvider).customWords.length,
        countAfterFirst,
        reason: 'duplicate must not be written to the wordbook',
      );
      expect(
        container.read(appControllerProvider).errorMessage,
        isNull,
        reason:
            'a duplicate is not an error; errorMessage stays null so the UI '
            'shows the "already in wordbook" message rather than a failure',
      );
    },
  );
}
