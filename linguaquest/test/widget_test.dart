import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/seed/seed_lessons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts at onboarding when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('LinguaQuest'), findsWidgets);
    expect(find.byIcon(Icons.route_outlined), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('renders redesigned home dashboard for an existing learner', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'widget-user',
      name: 'Ava',
      email: 'ava@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 240,
      streak: 6,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Today’s learning pack'), findsOneWidget);
    expect(find.text('Ready for Campus Starter?'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Learn'), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Word of the day'), findsOneWidget);
  });

  testWidgets('failed login stays on login screen and shows error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(_FailingAuth())],
        child: const LinguaQuestApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.textContaining('login failed'), findsOneWidget);
    expect(find.text('Today’s learning pack'), findsNothing);
  });

  testWidgets('dark theme keeps headline text readable', (tester) async {
    final dark = AppTheme.dark();
    final headlineColor = dark.textTheme.headlineMedium?.color;

    expect(headlineColor, isNotNull);
    expect(headlineColor, isNot(Colors.black));
  });

  test('seed learning path contains blueprint-sized lesson range', () {
    expect(seedLessons(), hasLength(greaterThanOrEqualTo(6)));
    expect(seedLessons(), hasLength(lessThanOrEqualTo(10)));
  });

  testWidgets('lesson mistake appears in review center after result', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'mistake-user',
      name: 'Mia',
      email: 'mia@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });

    await tester.pumpWidget(const ProviderScope(child: LinguaQuestApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Continue lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('讲座；授课'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('lecture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'deadline');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Go to review center'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to review center'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('commute'), 300);
    await tester.pumpAndSettle();
    expect(find.text('commute'), findsOneWidget);
    expect(find.text('Lesson'), findsWidgets);
  });
}

class _FailingAuth implements AuthRepository {
  @override
  Future<UserProfile?> loadSession() async => null;

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw Exception('login failed');
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw Exception('register failed');
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;

  @override
  Future<void> logout() async {}
}
