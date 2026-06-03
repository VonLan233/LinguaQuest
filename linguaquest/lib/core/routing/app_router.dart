import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/lesson_result.dart';
import '../../features/auth/goal_setup_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/ai_learning/ai_learning_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learning/learning_path_screen.dart';
import '../../features/learning/lesson_preview_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/about_screen.dart';
import '../../features/profile/help_support_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/quests/ai_tutor_screen.dart';
import '../../features/quests/class_mode_screen.dart';
import '../../features/quests/class_progress_screen.dart';
import '../../features/quests/leaderboard_screen.dart';
import '../../features/quests/progress_analytics_screen.dart';
import '../../features/quests/quest_screen.dart';
import '../../features/quiz/lesson_result_screen.dart';
import '../../features/quiz/quiz_session_screen.dart';
import '../../features/review/mistake_book_screen.dart';
import '../../features/review/review_center_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/study/new_study_screen.dart';
import '../../features/study/review_study_screen.dart';
import '../../features/training/training_screen.dart';
import '../../features/wordbook/add_edit_custom_word_screen.dart';
import '../../features/wordbook/custom_word_list_screen.dart';
import '../../features/wordbook/target_word_detail_screen.dart';
import '../../features/wordbook/word_detail_screen.dart';
import '../../features/wordbook/wordbook_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    overridePlatformDefaultLocation: true,
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
      ShellRoute(
        builder: (context, state, child) {
          final selectedIndex = _tabIndexForPath(state.uri.path);
          return AppShell(selectedIndex: selectedIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/training',
            builder: (context, state) => const TrainingScreen(),
          ),
          GoRoute(
            path: '/ai-learning',
            builder: (context, state) => const AiLearningScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/quest',
            builder: (context, state) => const QuestScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/learn',
        builder: (context, state) => const LearningPathScreen(),
      ),
      GoRoute(
        path: '/study/new',
        builder: (context, state) => const NewStudyScreen(),
      ),
      GoRoute(
        path: '/study/review',
        builder: (context, state) => const ReviewStudyScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewCenterScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/mistake-book',
        builder: (context, state) => const MistakeBookScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressAnalyticsScreen(),
      ),
      GoRoute(
        path: '/class-mode',
        builder: (context, state) => const ClassModeScreen(),
      ),
      GoRoute(
        path: '/class-progress',
        builder: (context, state) => const ClassProgressScreen(),
      ),
      GoRoute(
        path: '/ai-tutor',
        builder: (context, state) => const AiTutorScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/reminder',
        builder: (context, state) => const ReminderSettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
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
        path: '/timed-test/:id',
        builder: (context, state) => QuizSessionScreen(
          lessonId: state.pathParameters['id']!,
          mode: QuizSessionMode.timed,
        ),
      ),
      GoRoute(
        path: '/lesson/:id/result',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is LessonResultViewArgs) {
            return LessonResultScreen(
              result: extra.result,
              source: extra.source,
            );
          }
          return LessonResultScreen(
            result: extra is LessonResult ? extra : null,
          );
        },
      ),
    ],
  );
});

int _tabIndexForPath(String path) {
  if (path.startsWith('/training')) return 1;
  if (path.startsWith('/ai-learning')) return 2;
  if (path.startsWith('/discover')) return 3;
  if (path.startsWith('/quest')) return 3;
  if (path.startsWith('/profile')) return 4;
  return 0;
}
