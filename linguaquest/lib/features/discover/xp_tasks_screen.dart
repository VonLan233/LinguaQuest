import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';
import 'shared_widgets.dart';

class XpTasksScreen extends ConsumerWidget {
  const XpTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final claimed = state.todayClaimedRewardIds;
    final newLearningDone = state.todayCompletedFormalLessonIds.isNotEmpty;
    final reviewDone = state.todayReviewWordIds.isNotEmpty;
    final trainingDone = state.todayTrainingGameIds.isNotEmpty;
    final reviewedMistakeToday = state.customWords.any(
      (word) =>
          state.todayReviewWordIds.contains(word.id) && word.wrongCount > 0,
    );
    final weakCleanupDone = reviewedMistakeToday && state.weakWords.isEmpty;
    final checkedInToday = DateUtils.isSameDay(
      user?.lastStudyDate?.toLocal(),
      DateTime.now(),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: Text(l10n.discoverXpTasks),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RewardTaskList(
            tasks: [
              RewardTaskData(
                icon: Icons.calendar_month_outlined,
                title: l10n.discoverDailyCheckin,
                condition: l10n.discoverDailyCheckinCondition,
                points: 5,
                isDone: checkedInToday,
                isClaimed: claimed.contains('daily-checkin'),
                onTap: () => context.go('/home'),
                onClaim: () => _claimReward(
                  context,
                  ref,
                  id: 'daily-checkin',
                  title: l10n.discoverDailyCheckin,
                  points: 5,
                  isAvailable: checkedInToday,
                ),
              ),
              RewardTaskData(
                icon: Icons.school_outlined,
                title: l10n.discoverNewLearning,
                condition: l10n.discoverNewLearningCondition,
                points: 20,
                isDone: newLearningDone,
                isClaimed: claimed.contains('new-learning'),
                onTap: () => context.push('/study/new'),
                onClaim: () => _claimReward(
                  context,
                  ref,
                  id: 'new-learning',
                  title: l10n.discoverNewLearning,
                  points: 20,
                  isAvailable: newLearningDone,
                ),
              ),
              RewardTaskData(
                icon: Icons.replay_outlined,
                title: l10n.discoverReviewDone,
                condition: l10n.discoverReviewDoneCondition,
                points: 15,
                isDone: reviewDone,
                isClaimed: claimed.contains('review-done'),
                onTap: () => context.push('/study/review'),
                onClaim: () => _claimReward(
                  context,
                  ref,
                  id: 'review-done',
                  title: l10n.discoverReviewDone,
                  points: 15,
                  isAvailable: reviewDone,
                ),
              ),
              RewardTaskData(
                icon: Icons.sports_esports_outlined,
                title: l10n.discoverTrainingChallenge,
                condition: l10n.discoverTrainingChallengeCondition,
                points: 20,
                isDone: trainingDone,
                isClaimed: claimed.contains('training-challenge'),
                onTap: () => context.go('/training'),
                onClaim: () => _claimReward(
                  context,
                  ref,
                  id: 'training-challenge',
                  title: l10n.discoverTrainingChallenge,
                  points: 20,
                  isAvailable: trainingDone,
                ),
              ),
              RewardTaskData(
                icon: Icons.cleaning_services_outlined,
                title: l10n.discoverWeakCleanup,
                condition: l10n.discoverWeakCleanupCondition,
                points: 10,
                isDone: weakCleanupDone,
                isClaimed: claimed.contains('weak-cleanup'),
                onTap: () => context.push('/review'),
                onClaim: () => _claimReward(
                  context,
                  ref,
                  id: 'weak-cleanup',
                  title: l10n.discoverWeakCleanup,
                  points: 10,
                  isAvailable: weakCleanupDone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _claimReward(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required String title,
    required int points,
    required bool isAvailable,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .claimReward(id: id, points: points, isAvailable: isAvailable);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final currentXp = ref.read(appControllerProvider).user?.xp ?? 0;
    final message = succeeded
        ? l10n.discoverClaimedMessage(
            title,
            points.toString(),
            currentXp.toString(),
          )
        : ref.read(appControllerProvider).errorMessage ??
              l10n.discoverCannotClaim;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(message),
        action: succeeded
            ? SnackBarAction(
                label: l10n.discoverViewProfile,
                onPressed: () => context.go('/profile'),
              )
            : null,
      ),
    );
  }
}
