import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/mascot_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../data/models/custom_word.dart';
import '../../l10n/generated/app_localizations.dart';

/// Deterministic Word-of-the-Day index: rotates daily, stable within a day.
int wordOfDayIndex(int epochDay, int wordCount) {
  if (wordCount <= 0) return 0;
  return epochDay % wordCount;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final currentBook = state.currentWordBook;
    final dueCount = state.reviewQueue.length;
    final dailyGoal = state.dailyNewTarget;
    final todayLessonWords = state.todayLearningWords;
    final todayWork = todayLessonWords + state.todayReviewWordIds.length;
    // Stable denominator: reviewing a due word moves it from "due" to "done"
    // without shrinking the total, so progress can't overshoot (the "5/4" bug).
    final totalWork = state.isStudyPlanPaused
        ? 0
        : dailyGoal + state.dailyReviewTarget;
    final dailyProgress = totalWork <= 0
        ? 0.0
        : (todayWork / totalWork).clamp(0.0, 1.0);
    final currentLesson = state.currentLesson;
    final pathComplete =
        state.formalLessons.isNotEmpty &&
        state.formalLessons.every((lesson) => lesson.status == 'completed');
    final wodPool = currentLesson?.words ?? const [];
    final wordOfDay = wodPool.isNotEmpty
        ? wodPool[wordOfDayIndex(
            DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
            wodPool.length,
          )]
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => Tooltip(
                message: 'Menu',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.s4),
                    child: Icon(
                      AppIcons.menu,
                      size: 24,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s4),
            Tooltip(
              message: l10n.homePersonalSpace,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  final uid = state.user?.uid;
                  if (uid != null && uid.isNotEmpty) {
                    context.push('/profile/$uid');
                  } else {
                    context.go('/profile');
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: MascotImage(size: 40),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => context.push('/search'),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(AppIcons.search),
                      hintText: l10n.homeSearchHint,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppTokens.s8,
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            _NotificationBellButton(
              unreadCount: state.unreadNotificationCount,
              onPressed: () => context.push('/notifications'),
              l10n: l10n,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: _DailyFocusHeader(
            streak: user?.streak ?? 0,
            target:
                currentBook?.nameFor(localeCode) ??
                displayTarget(user?.targetExam, l10n: l10n),
            level: state.isStudyPlanPaused
                ? l10n.homePlanPaused
                : displayLevel(user?.level, l10n: l10n),
            todayWork: todayWork,
            totalWork: totalWork,
            progress: dailyProgress,
            isPaused: state.isStudyPlanPaused,
            onTargetTap: () => showLanguageWordbookPicker(context),
            l10n: l10n,
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s16,
          ),
          child: _HomeLearningSignals(
            completedWords: state.completedLearningWords,
            masteredWords: state.masteredReviewWords,
            dueWords: state.dueWords.length,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          child: _DailyTaskPanel(
            currentSection:
                currentLesson?.section ??
                currentBook?.nameFor(localeCode) ??
                (user?.targetExam != null
                    ? displayTarget(user!.targetExam, l10n: l10n)
                    : l10n.commonWordbook),
            dailyGoal: dailyGoal,
            dueCount: dueCount,
            isPaused: state.isStudyPlanPaused,
            canStartNew:
                currentLesson != null &&
                !pathComplete &&
                !state.isStudyPlanPaused,
            onOpenPlan: () => context.push('/settings/study-plan'),
            onNewStudy: () => context.push('/study/new'),
            onReview: () => context.push('/study/review'),
          ),
        ),
        const SizedBox(height: AppTokens.s20),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s8,
          ),
          child: _HomeShortcutList(
            actions: [
              _HomeShortcutData(
                icon: AppIcons.menuBook,
                title: l10n.homeWordbookShortcut,
                subtitle: currentBook == null
                    ? '${state.totalLearningWords} ${l10n.commonWords}'
                    : '${currentBook.totalWords} ${l10n.commonWords}',
                onTap: () => context.push('/wordbook'),
              ),
              _HomeShortcutData(
                icon: AppIcons.article,
                title: l10n.homeDailyArticle,
                subtitle: l10n.homeDailyArticleSubtitle,
                onTap: () => context.push('/reading'),
              ),
              _HomeShortcutData(
                icon: AppIcons.route,
                title: l10n.homeLearningPath,
                subtitle:
                    currentBook?.nameFor(localeCode) ??
                    l10n.homeLearningPathSubtitle,
                onTap: () => context.push('/learn'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s20),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s8,
          ),
          child: _HomeInfoLink(
            cue: wordOfDay?.imageCue ?? '🌟',
            title: l10n.homeWordOfDay,
            body: wordOfDay == null
                ? l10n.homeOpenWordCard
                : '${wordOfDay.word} · ${wordOfDay.primaryDefinitionFor(Localizations.localeOf(context).languageCode)}',
            onTap: () => wordOfDay == null
                ? context.push('/wordbook')
                : context.push('/wordbook/${wordOfDay.id}'),
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.homeWeakWords,
                subtitle: state.weakWords.isEmpty
                    ? l10n.homeNoWeakWords
                    : l10n.homeWeakWordsReview,
                trailing: TextButton(
                  onPressed: () => context.push('/study/review'),
                  child: Text(l10n.commonReview),
                ),
              ),
              if (state.weakWords.isEmpty)
                MascotEmptyState(
                  title: l10n.homeNoWeakWords,
                  message: l10n.homeWeakWordsEmptyHint,
                  action: AppSecondaryButton(
                    label: l10n.commonReview,
                    onPressed: () => context.push('/study/review'),
                  ),
                )
              else ...[
                const SizedBox(height: 8),
                ...state.weakWords
                    .take(3)
                    .map((word) => _WeakWordLink(word: word)),
                if (state.weakWords.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('home-see-all-mistakes'),
                      onPressed: () => context.push('/mistake-book'),
                      child: Text(l10n.commonViewAll),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({
    required this.unreadCount,
    required this.l10n,
    required this.onPressed,
  });

  final int unreadCount;
  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        QuestIconButton(
          tooltip: l10n.homeNotifications,
          onPressed: onPressed,
          icon: AppIcons.notifications,
          color: AppTheme.coral,
        ),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.coral,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeLearningSignals extends StatelessWidget {
  const _HomeLearningSignals({
    required this.completedWords,
    required this.masteredWords,
    required this.dueWords,
    required this.l10n,
  });

  final int completedWords;
  final int masteredWords;
  final int dueWords;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            label: l10n.homeLearned,
            value: '$completedWords',
            icon: AppIcons.school,
            accent: AppTheme.cyan,
          ),
        ),
        const _HomeSignalDivider(),
        Expanded(
          child: StatTile(
            label: l10n.homeMastered,
            value: '$masteredWords',
            icon: AppIcons.verified,
            accent: AppTheme.success,
          ),
        ),
        const _HomeSignalDivider(),
        Expanded(
          child: StatTile(
            label: l10n.homeReviewLabel,
            value: '$dueWords',
            icon: AppIcons.replay,
            accent: AppTheme.mango,
          ),
        ),
      ],
    );
  }
}

class _HomeSignalDivider extends StatelessWidget {
  const _HomeSignalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: VerticalDivider(
        width: 16,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _HomeInfoLink extends StatelessWidget {
  const _HomeInfoLink({
    required this.cue,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String cue;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
          child: Row(
            children: [
              ImageCueBadge(cue: cue, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTaskPanel extends StatelessWidget {
  const _DailyTaskPanel({
    required this.currentSection,
    required this.dailyGoal,
    required this.dueCount,
    required this.isPaused,
    required this.canStartNew,
    required this.onOpenPlan,
    required this.onNewStudy,
    required this.onReview,
  });

  final String currentSection;
  final int dailyGoal;
  final int dueCount;
  final bool isPaused;
  final bool canStartNew;
  final VoidCallback onOpenPlan;
  final VoidCallback onNewStudy;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasReview = dueCount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeTaskConsole,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (isPaused)
            AppPrimaryButton(
              onPressed: onOpenPlan,
              icon: AppIcons.playCircle,
              label: l10n.homeResumePlan,
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    onPressed: canStartNew
                        ? onNewStudy
                        : (hasReview ? onReview : null),
                    icon: AppIcons.playArrow,
                    label: l10n.homeStartLearning,
                  ),
                ),
                if (hasReview) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppSecondaryButton(
                      onPressed: onReview,
                      label: l10n.homeReviewOnly,
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onOpenPlan,
            icon: const Icon(AppIcons.tune),
            label: Text(l10n.homeAdjustPlan),
          ),
        ],
      ),
    );
  }
}

class _DailyFocusHeader extends StatelessWidget {
  const _DailyFocusHeader({
    required this.streak,
    required this.target,
    required this.level,
    required this.todayWork,
    required this.totalWork,
    required this.progress,
    required this.isPaused,
    required this.l10n,
    this.onTargetTap,
  });

  final int streak;
  final String target;
  final String level;
  final int todayWork;
  final int totalWork;
  final double progress;
  final bool isPaused;
  final AppLocalizations l10n;
  final VoidCallback? onTargetTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            GestureDetector(
              onTap: onTargetTap,
              child: AppPill(
                label: '$target · $level',
                icon: AppIcons.trackChanges,
              ),
            ),
            AppPill(
              variant: PillVariant.streak,
              icon: AppIcons.localFireDepartment,
              label: l10n.homeStreakDays(streak),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPaused ? l10n.homePlanPaused : l10n.homeTodayCompleted,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  if (!isPaused) ...[
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      '$todayWork/$totalWork ${l10n.commonWords}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            _DailyProgressRing(progress: progress),
          ],
        ),
      ],
    );
  }
}

class _DailyProgressRing extends StatelessWidget {
  const _DailyProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return SizedBox.square(
      dimension: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 96,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: AppTheme.progressTrack(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.leaf),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                l10n.homeTodayProgress,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeShortcutList extends StatelessWidget {
  const _HomeShortcutList({required this.actions});

  final List<_HomeShortcutData> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          _HomeShortcutLink(data: actions[index]),
          if (index != actions.length - 1)
            const SizedBox(height: AppTokens.s12),
        ],
      ],
    );
  }
}

class _HomeShortcutLink extends StatelessWidget {
  const _HomeShortcutLink({required this.data});

  final _HomeShortcutData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
          child: Row(
            children: [
              Icon(data.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeShortcutData {
  const _HomeShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _WeakWordLink extends StatelessWidget {
  const _WeakWordLink({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${customWordMeaningFor(word, localeCode)} · ${l10n.commonMastery} ${word.masteryLevel}/5',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(AppIcons.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
