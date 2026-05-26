import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/widgets/quest_card.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/seed/seed_lessons.dart';
import 'package:linguaquest/features/auth/goal_setup_screen.dart';
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

  testWidgets('goal setup choices keep a stable size when selected', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GoalSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dailyEnglish = find.byKey(const ValueKey('choice-Daily English'));
    final businessEnglish = find.byKey(
      const ValueKey('choice-Business English'),
    );

    final dailyEnglishSize = tester.getSize(dailyEnglish);
    final businessEnglishSize = tester.getSize(businessEnglish);

    await tester.tap(businessEnglish);
    await tester.pumpAndSettle();

    expect(tester.getSize(dailyEnglish), dailyEnglishSize);
    expect(tester.getSize(businessEnglish), businessEnglishSize);

    final elementary = find.byKey(const ValueKey('choice-Elementary'));
    final advanced = find.byKey(const ValueKey('choice-Advanced'));

    await tester.scrollUntilVisible(elementary, 120);
    await tester.pumpAndSettle();

    final elementarySize = tester.getSize(elementary);
    final advancedSize = tester.getSize(advanced);

    await tester.tap(advanced);
    await tester.pumpAndSettle();

    expect(tester.getSize(elementary), elementarySize);
    expect(tester.getSize(advanced), advancedSize);
  });

  testWidgets('dark semantic surfaces keep readable contrast', (tester) async {
    late Color warmSurface;
    late Color accentSurface;
    late Color selectedSurface;
    late Color onSurface;
    late Color onSelectedSurface;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            warmSurface = AppTheme.warmSurface(context);
            accentSurface = AppTheme.accentSurface(context);
            selectedSurface = AppTheme.selectedSurface(context);
            onSurface = scheme.onSurface;
            onSelectedSurface = scheme.onPrimaryContainer;

            return Scaffold(
              body: Column(
                children: [
                  QuestCard(
                    color: warmSurface,
                    child: const Text('Warm surface text'),
                  ),
                  QuestCard(
                    color: accentSurface,
                    child: const Text('Accent surface text'),
                  ),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: AppTheme.progressTrack(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(_contrastRatio(onSurface, warmSurface), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(onSurface, accentSurface), greaterThanOrEqualTo(4.5));
    expect(
      _contrastRatio(onSelectedSurface, selectedSurface),
      greaterThanOrEqualTo(4.5),
    );
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

  testWidgets('lesson and quiz screens expose a working back path', (
    tester,
  ) async {
    final now = DateTime(2026, 5, 25);
    final profile = UserProfile(
      uid: 'back-user',
      name: 'Noah',
      email: 'noah@lingua.quest',
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

    expect(find.text('Start quiz'), findsWidgets);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Today’s learning pack'), findsOneWidget);

    await tester.tap(find.text('Continue lesson'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz').first);
    await tester.pumpAndSettle();

    expect(find.text('Check'), findsOneWidget);
    expect(find.byType(BackButtonIcon), findsOneWidget);

    await tester.tap(find.text('讲座；授课'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Leave quiz?'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.text('Check'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Start quiz'), findsWidgets);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
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
