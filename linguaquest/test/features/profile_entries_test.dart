import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/data/models/study_plan.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'ProfileScreen contains Privacy, Data & storage, and Notifications entries',
    (tester) async {
      final now = DateTime(2026, 6, 20);
      final profile = UserProfile(
        uid: 'profile-entries-test-user',
        name: 'Tester',
        email: 'test@lingua.quest',
        targetExam: 'IELTS',
        level: 'Elementary',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      final plan = StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: 'HSK 1',
        dailyGoal: 10,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
        'linguaquest.studyPlan.${profile.uid}': jsonEncode(plan.toJson()),
      });

      await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigate to the Profile tab (label is 'Me' per l10n.tabProfile).
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();

      // Scroll to reveal all settings items.
      await tester.scrollUntilVisible(
        find.text('Privacy'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Data & storage'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Data & storage'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Notifications'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // 'Notifications' appears as the profile entry label (among others).
      expect(find.text('Notifications'), findsWidgets);
    },
  );
}
