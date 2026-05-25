import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/lesson_result.dart';
import '../../features/auth/goal_setup_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learning/learning_path_screen.dart';
import '../../features/learning/lesson_preview_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quests/quest_screen.dart';
import '../../features/quiz/lesson_result_screen.dart';
import '../../features/quiz/quiz_session_screen.dart';
import '../../features/review/review_center_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/wordbook/add_edit_custom_word_screen.dart';
import '../../features/wordbook/custom_word_list_screen.dart';
import '../../features/wordbook/target_word_detail_screen.dart';
import '../../features/wordbook/word_detail_screen.dart';
import '../../features/wordbook/wordbook_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/goal-setup',
        builder: (context, state) => const GoalSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const AppShell(selectedIndex: 0, child: HomeScreen()),
      ),
      GoRoute(
        path: '/learn',
        builder: (context, state) =>
            const AppShell(selectedIndex: 1, child: LearningPathScreen()),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) =>
            const AppShell(selectedIndex: 2, child: ReviewCenterScreen()),
      ),
      GoRoute(
        path: '/quest',
        builder: (context, state) =>
            const AppShell(selectedIndex: 3, child: QuestScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const AppShell(selectedIndex: 4, child: ProfileScreen()),
      ),
      GoRoute(
        path: '/wordbook',
        builder: (context, state) => const WordbookScreen(),
      ),
      GoRoute(
        path: '/wordbook/:id',
        builder: (context, state) =>
            TargetWordDetailScreen(wordId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/custom-words',
        builder: (context, state) => const CustomWordListScreen(),
      ),
      GoRoute(
        path: '/custom-words/new',
        builder: (context, state) => const AddEditCustomWordScreen(),
      ),
      GoRoute(
        path: '/custom-words/:id',
        builder: (context, state) =>
            WordDetailScreen(wordId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/custom-words/:id/edit',
        builder: (context, state) =>
            AddEditCustomWordScreen(wordId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/lesson/:id',
        builder: (context, state) =>
            LessonPreviewScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:id/quiz',
        builder: (context, state) =>
            QuizSessionScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:id/result',
        builder: (context, state) =>
            LessonResultScreen(result: state.extra as LessonResult?),
      ),
    ],
  );
});
