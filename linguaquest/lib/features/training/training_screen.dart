import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/compact_entry_card.dart';
import '../../l10n/generated/app_localizations.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final trainingLessons = state.lessons
        .where((lesson) => lesson.isTrainingPack)
        .toList();
    final speedLesson = trainingLessons.isEmpty ? null : trainingLessons.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s24,
        AppTokens.s24,
        AppTokens.s24,
        32,
      ),
      children: [
        Text(
          l10n.tabTraining,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 28),
        _TrainingGoalHeader(
          weeklyXp: user?.xp ?? 0,
          dailyAvailable: l10n.trainingDailyXpAvailable,
          weeklyPrefix: l10n.trainingWeeklyXpPrefix,
          streak: user?.streak ?? 0,
          streakLabel: l10n.homeStreakLabel,
        ),
        const SizedBox(height: AppTokens.s32),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: AppIcons.school,
              title: l10n.trainingCampusSpeed,
              color: AppTokens.successColor(context),
              onTap: speedLesson == null
                  ? null
                  : () => context.push('/timed-test/${speedLesson.id}'),
            ),
            _TrainingGameRow(
              icon: AppIcons.timer,
              title: l10n.trainingSpeedGame,
              color: AppTokens.mangoColor(context),
              onTap: () => context.push('/training/word-rush'),
            ),
            _TrainingGameRow(
              icon: AppIcons.stairs,
              title: l10n.trainingSurvivor,
              color: AppTokens.coralColor(context),
              onTap: () => context.push('/training/survival'),
            ),
            _TrainingGameRow(
              icon: AppIcons.editNote,
              title: l10n.trainingSpelling,
              color: AppTheme.cyan,
              onTap: () => context.push('/training/spelling'),
            ),
            _TrainingGameRow(
              icon: AppIcons.article,
              title: l10n.trainingPassageCloze,
              color: AppTokens.successColor(context),
              onTap: () => context.push('/training/passage-cloze'),
            ),
            _TrainingGameRow(
              icon: AppIcons.hearing,
              title: l10n.trainingListening,
              color: AppTokens.mangoColor(context),
              onTap: () => context.push('/training/listening-sprint'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(weeklyPrefix, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Text('$weeklyXp XP', style: theme.textTheme.displayMedium),
        const SizedBox(height: 12),
        Text(dailyAvailable, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text('$streak $streakLabel', style: theme.textTheme.bodySmall),
        const SizedBox(height: 24),
        const Divider(),
      ],
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
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null;
    return CompactEntryCard(
      icon: icon,
      title: title,
      color: color,
      onTap: onTap,
      enabled: !locked,
      trailing: locked
          ? AppPill(
              label: AppLocalizations.of(context).trainingComingSoon,
              variant: PillVariant.primary,
              icon: AppIcons.lockClock,
            )
          : null,
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
