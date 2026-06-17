import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final localeCode = Localizations.localeOf(context).languageCode;
    final currentBook = state.currentWordBook;
    final studyBookName = displayWordbookTitle(
      state.currentStudyBook.id,
      l10n: l10n,
    );
    final studyBookTitle = studyBookName.isNotEmpty
        ? studyBookName
        : l10n.searchCurrentPlan;
    final trainingLessons = state.lessons
        .where((lesson) => lesson.isTrainingPack)
        .toList();
    final speedLesson = trainingLessons.isEmpty ? null : trainingLessons.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s16,
        AppTokens.s20,
        AppTokens.s16,
        88,
      ),
      children: [
        _TrainingGoalHeader(
          weeklyXp: user?.xp ?? 0,
          dailyAvailable: l10n.trainingDailyXpAvailable,
          weeklyPrefix: l10n.trainingWeeklyXpPrefix,
          streak: user?.streak ?? 0,
          streakLabel: l10n.homeStreakLabel,
        ),
        const SizedBox(height: AppTokens.s32),
        Text(
          l10n.trainingTimedTests,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTokens.s12),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: AppIcons.school,
              title: l10n.trainingCampusSpeed,
              subtitle: currentBook == null
                  ? '$studyBookTitle · ${l10n.trainingTimedTests}'
                  : '${currentBook.nameFor(localeCode)} · ${l10n.trainingTimedTests}',
              color: AppTokens.successColor(context),
              onTap: speedLesson == null
                  ? null
                  : () => context.push('/timed-test/${speedLesson.id}'),
            ),
            _TrainingGameRow(
              icon: AppIcons.timer,
              title: l10n.trainingSpeedGame,
              subtitle: l10n.trainingSpeedGameDesc,
              color: AppTokens.mangoColor(context),
              onTap: () => context.push('/training/word-rush'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s24),
        SectionHeader(
          title: l10n.trainingSpecialDrills,
          subtitle: l10n.trainingSpecialDrillsSubtitle,
        ),
        const SizedBox(height: AppTokens.s12),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: AppIcons.stairs,
              title: l10n.trainingSurvivor,
              subtitle: l10n.trainingSurvivorDesc,
              color: AppTokens.coralColor(context),
              onTap: () => context.push('/training/survival'),
            ),
            _TrainingGameRow(
              icon: AppIcons.editNote,
              title: l10n.trainingSpelling,
              subtitle: l10n.trainingSpellingDesc,
              color: AppTheme.cyan,
              onTap: () => context.push('/training/spelling'),
            ),
            _TrainingGameRow(
              icon: AppIcons.article,
              title: l10n.trainingPassageCloze,
              subtitle: l10n.trainingPassageClozeDesc,
              color: AppTokens.successColor(context),
              onTap: null,
            ),
            _TrainingGameRow(
              icon: AppIcons.hearing,
              title: l10n.trainingListening,
              subtitle: l10n.trainingListeningDesc,
              color: AppTokens.mangoColor(context),
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s32),
        _TrainingReadinessLine(
          dueWords: state.dueWords.length,
          weakWords: state.weakWords.length,
          comboTarget: 10,
          l10n: l10n,
        ),
      ],
    );
  }
}

class _TrainingGoalHeader extends StatelessWidget {
  const _TrainingGoalHeader({
    required this.weeklyXp,
    required this.dailyAvailable,
    required this.weeklyPrefix,
    required this.streak,
    required this.streakLabel,
  });

  final int weeklyXp;
  final String dailyAvailable;
  final String weeklyPrefix;
  final int streak;
  final String streakLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s16,
        AppTokens.s20,
        AppTokens.s20,
      ),
      child: Row(
        children: [
          const IconCueBadge(icon: AppIcons.bolt, color: AppTokens.mango),
          const SizedBox(width: AppTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$weeklyPrefix $weeklyXp XP',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  dailyAvailable,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          AppPill(
            label: '$streak $streakLabel',
            variant: PillVariant.streak,
            icon: AppIcons.localFireDepartment,
          ),
        ],
      ),
    );
  }
}

class _TrainingGameList extends StatelessWidget {
  const _TrainingGameList({required this.children});

  final List<_TrainingGameRow> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            const SizedBox(height: AppTokens.s12),
        ],
      ],
    );
  }
}

class _TrainingGameRow extends StatelessWidget {
  const _TrainingGameRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = onTap == null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            if (locked)
              AppPill(
                label: AppLocalizations.of(context).trainingComingSoon,
                variant: PillVariant.primary,
                icon: AppIcons.lockClock,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      onTap: onTap,
      child: locked ? Opacity(opacity: 0.6, child: content) : content,
    );
  }
}

class _TrainingReadinessLine extends StatelessWidget {
  const _TrainingReadinessLine({
    required this.dueWords,
    required this.weakWords,
    required this.comboTarget,
    required this.l10n,
  });

  final int dueWords;
  final int weakWords;
  final int comboTarget;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TrainingReadinessItem(
              value: '$dueWords',
              label: l10n.trainingDueWords,
              icon: AppIcons.today,
              accent: AppTokens.azure,
            ),
          ),
          Expanded(
            child: _TrainingReadinessItem(
              value: '$weakWords',
              label: l10n.trainingWeakWords,
              icon: AppIcons.warningAmber,
              accent: AppTokens.coralColor(context),
            ),
          ),
          Expanded(
            child: _TrainingReadinessItem(
              value: '$comboTarget',
              label: l10n.trainingComboTarget,
              icon: AppIcons.bolt,
              accent: AppTokens.mangoColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingReadinessItem extends StatelessWidget {
  const _TrainingReadinessItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(height: AppTokens.s8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
