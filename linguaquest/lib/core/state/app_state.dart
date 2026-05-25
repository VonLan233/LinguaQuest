import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/user_profile.dart';

class AppState {
  const AppState({
    required this.isBootstrapped,
    required this.isLoading,
    required this.lessons,
    required this.customWords,
    this.user,
    this.lastResult,
    this.errorMessage,
  });

  final bool isBootstrapped;
  final bool isLoading;
  final UserProfile? user;
  final List<Lesson> lessons;
  final List<CustomWord> customWords;
  final LessonResult? lastResult;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  List<CustomWord> get dueWords {
    final now = DateTime.now();
    return customWords.where((word) => word.isDue(now)).toList();
  }

  List<CustomWord> get weakWords {
    final weak = customWords.where((word) => word.isWeak).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak;
  }

  AppState copyWith({
    bool? isBootstrapped,
    bool? isLoading,
    UserProfile? user,
    bool clearUser = false,
    List<Lesson>? lessons,
    List<CustomWord>? customWords,
    LessonResult? lastResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppState(
      isBootstrapped: isBootstrapped ?? this.isBootstrapped,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      lessons: lessons ?? this.lessons,
      customWords: customWords ?? this.customWords,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory AppState.initial() {
    return const AppState(
      isBootstrapped: false,
      isLoading: false,
      lessons: [],
      customWords: [],
    );
  }
}
