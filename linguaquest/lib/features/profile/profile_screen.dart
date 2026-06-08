import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

int newWordbookCount(AppState state) => state.customWords.length;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final completedPlans = state.learningPathProgress >= 1 ? 1 : 0;
    final reviewWords = state.reviewWords;
    final masteredWords = reviewWords
        .where((word) => word.masteryLevel >= 4 || word.status == 'Mastered')
        .length;
    final totalAttempts = reviewWords.fold<int>(
      0,
      (total, word) => total + word.correctCount + word.wrongCount,
    );
    final correctAttempts = reviewWords.fold<int>(
      0,
      (total, word) => total + word.correctCount,
    );
    final averageAccuracy = totalAttempts == 0
        ? 0
        : (correctAttempts / totalAttempts * 100).round();
    final weakestWord = state.weakWords.isEmpty ? null : state.weakWords.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        _ProfileIdentityHeader(
          name: user?.name ?? l10n.profileLearner,
          email: user?.email ?? l10n.profileNoEmail,
          target: displayTarget(user?.targetExam, l10n: l10n),
          level: displayLevel(user?.level, l10n: l10n),
          xp: user?.xp ?? 0,
          streak: user?.streak ?? 0,
          l10n: l10n,
        ),
        const SizedBox(height: 20),
        SectionHeader(
            title: l10n.profileDashboard,
            subtitle: l10n.profileDashboardSubtitle),
        const SizedBox(height: 12),
        _ProfileScoreboard(
          stats: [
            _ProfileStatData(
              label: l10n.profileLearnedWords,
              value: '${state.completedLearningWords}',
              icon: Icons.school_outlined,
              color: AppTheme.teal,
            ),
            _ProfileStatData(
              label: l10n.profileMasteredWords,
              value: '$masteredWords',
              icon: Icons.verified_outlined,
              color: AppTheme.success,
            ),
            _ProfileStatData(
              label: l10n.profileCustomWords,
              value: '${newWordbookCount(state)}',
              icon: Icons.style_outlined,
              color: AppTheme.cyan,
            ),
            _ProfileStatData(
              label: l10n.profileAverageAccuracy,
              value: '$averageAccuracy%',
              icon: Icons.percent_outlined,
              color: AppTheme.mango,
            ),
            _ProfileStatData(
              label: l10n.profilePlansCompleted,
              value: '$completedPlans',
              icon: Icons.flag_outlined,
              color: AppTheme.teal,
            ),
            _ProfileStatData(
              label: l10n.onboardingTagPillStreak,
              value: '${user?.streak ?? 0} ${l10n.profileStreakDays}',
              icon: Icons.local_fire_department,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _ProfileProgressSummary(
          progress: state.learningPathProgress,
          completedWords: state.completedLearningWords,
          totalWords: state.totalLearningWords,
          todayLessons: state.todayCompletedFormalLessonIds.length,
          todayReviews: state.todayReviewWordIds.length,
          l10n: l10n,
        ),
        const SizedBox(height: 22),
        _WeaknessStatusLine(
          text: weakestWord == null
              ? l10n.profileNoWeakness
              : '${l10n.profileMostWrongWord}${l10n.localeName == 'zh' ? '：' : ': '}${weakestWord.word} · ${weakestWord.wrongCount} ${l10n.quizMistakes} · ${displayWordStatus(weakestWord.status, l10n: l10n)}',
        ),
        const SizedBox(height: 22),
        if (state.studyPlan != null) ...[
          _LearningPlanLine(
            wordBookName: state.currentStudyBook.name,
            dailyNewTarget: state.studyPlan!.dailyNewTarget,
            dailyReviewLimit: state.studyPlan!.dailyReviewLimit,
            status: state.studyPlan!.status,
            l10n: l10n,
          ),
          const SizedBox(height: 22),
        ],
        SectionHeader(title: l10n.profileSettingsSupport),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.flag_outlined,
          title: l10n.profilePlanLabel,
          subtitle: state.currentStudyBook.name,
          route: '/settings/study-plan',
        ),
        _ProfileAction(
          icon: Icons.menu_book_outlined,
          title: l10n.commonWordbook,
          subtitle: l10n.profileWordbookSubtitle,
          route: '/wordbook',
        ),
        _ProfileAction(
          icon: Icons.style_outlined,
          title: l10n.commonCustomWords,
          subtitle: l10n.profileCustomWordsSubtitle,
          route: '/custom-words',
        ),
        _ProfileAction(
          icon: Icons.warning_amber_outlined,
          title: l10n.commonMistakeBook,
          subtitle: l10n.profileMistakeBookSubtitle,
          route: '/mistake-book',
        ),
        _ProfileAction(
          icon: Icons.notifications_outlined,
          title: l10n.commonDailyReminder,
          subtitle: l10n.profileReminderSubtitle,
          route: '/settings/reminder',
        ),
        _ProfileAction(
          icon: Icons.dark_mode_outlined,
          title: l10n.commonTheme,
          subtitle: l10n.profileDarkModeSubtitle,
          route: '/settings/theme',
        ),
        _ProfileAction(
          icon: Icons.help_outline,
          title: l10n.profileHelpTitle,
          subtitle: l10n.profileHelpSubtitle,
          route: '/help',
        ),
        _ProfileAction(
          icon: Icons.info_outline,
          title: l10n.profileAboutTitle,
          subtitle: l10n.profileAboutSubtitle,
          route: '/about',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(appControllerProvider.notifier).logout();
            if (context.mounted) context.go('/onboarding');
          },
          icon: const Icon(Icons.logout),
          label: Text(l10n.profileLogout),
        ),
      ],
    );
  }
}

class _ProfileIdentityHeader extends StatelessWidget {
  const _ProfileIdentityHeader({
    required this.name,
    required this.email,
    required this.target,
    required this.level,
    required this.xp,
    required this.streak,
    required this.l10n,
  });

  final String name;
  final String email;
  final String target;
  final String level;
  final int xp;
  final int streak;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            (name.trim().isEmpty)
                ? '?'
                : name.trim().characters.first.toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 3),
              Text(
                '$email · $target · $level',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PillLabel(
                    label: '$xp ${l10n.commonXP}',
                    icon: Icons.bolt,
                    color: AppTheme.mango,
                  ),
                  PillLabel(
                    label: '$streak ${l10n.profileStreakDays}',
                    icon: Icons.local_fire_department,
                    color: AppTheme.coral,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileScoreboard extends StatelessWidget {
  const _ProfileScoreboard({required this.stats});

  final List<_ProfileStatData> stats;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < stats.length; index += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _ProfileStatLine(data: stats[index])),
            const SizedBox(width: 14),
            Expanded(
              child: index + 1 < stats.length
                  ? _ProfileStatLine(data: stats[index + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (index + 2 < stats.length) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        );
      }
    }

    return Column(children: rows);
  }
}

class _ProfileStatLine extends StatelessWidget {
  const _ProfileStatLine({required this.data});

  final _ProfileStatData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconCueBadge(icon: data.icon, color: data.color, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 1),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatData {
  const _ProfileStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ProfileProgressSummary extends StatelessWidget {
  const _ProfileProgressSummary({
    required this.progress,
    required this.completedWords,
    required this.totalWords,
    required this.todayLessons,
    required this.todayReviews,
    required this.l10n,
  });

  final double progress;
  final int completedWords;
  final int totalWords;
  final int todayLessons;
  final int todayReviews;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.profileCurrentBookProgress,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppTheme.progressTrack(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$completedWords/$totalWords ${l10n.commonWords} · ${l10n.homeTodayProgress}: $todayLessons ${l10n.commonLessons} · ${l10n.commonReview} $todayReviews ${l10n.commonWords}',
        ),
      ],
    );
  }
}

class _WeaknessStatusLine extends StatelessWidget {
  const _WeaknessStatusLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconCueBadge(
          icon: Icons.analytics_outlined,
          color: theme.colorScheme.primary,
          size: 38,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.42,
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningPlanLine extends StatelessWidget {
  const _LearningPlanLine({
    required this.wordBookName,
    required this.dailyNewTarget,
    required this.dailyReviewLimit,
    required this.status,
    required this.l10n,
  });

  final String wordBookName;
  final int dailyNewTarget;
  final int dailyReviewLimit;
  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.event_available_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profilePlanLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '$wordBookName · ${l10n.commonNew} $dailyNewTarget · ${l10n.goalSetupReviewLimit} $dailyReviewLimit · ${status == 'paused' ? l10n.profilePlanPaused : l10n.profilePlanRunning}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                IconCueBadge(icon: icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
