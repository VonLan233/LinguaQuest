import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../l10n/generated/app_localizations.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final currentBook = state.currentWordBook;
    final trainingLessons = state.lessons
        .where((lesson) => lesson.isTrainingPack)
        .toList();
    final speedLesson = trainingLessons.isEmpty ? null : trainingLessons.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: '本周 ${user?.xp ?? 0} XP',
              icon: Icons.bolt,
              color: AppTheme.mango,
            ),
            const PillLabel(
              label: '今日可得 60 XP',
              icon: Icons.add_task_outlined,
              color: AppTheme.leaf,
            ),
            PillLabel(
              label: '${user?.streak ?? 0} ${l10n.homeStreakLabel}',
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          l10n.trainingTimedTests,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: Icons.school_outlined,
              title: l10n.trainingCampusSpeed,
              subtitle: currentBook == null
                  ? '${state.currentStudyBook.name} · 限时测试'
                  : '${currentBook.title} · 限时测试',
              color: AppTheme.leaf,
              onTap: speedLesson == null
                  ? null
                  : () => context.push('/timed-test/${speedLesson.id}'),
            ),
            _TrainingGameRow(
              icon: Icons.timer_outlined,
              title: l10n.trainingSpeedGame,
              subtitle: l10n.trainingSpeedGameDesc,
              color: AppTheme.mango,
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          l10n.trainingSpecialDrills,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.trainingSpecialDrillsSubtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _TrainingGameRow(
          icon: Icons.stairs_outlined,
          title: l10n.trainingSurvivor,
          subtitle: l10n.trainingSurvivorDesc,
          color: AppTheme.coral,
          onTap: null,
        ),
        const SizedBox(height: 12),
        _TrainingGameRow(
          icon: Icons.edit_note_outlined,
          title: l10n.trainingSpelling,
          subtitle: l10n.trainingSpellingDesc,
          color: AppTheme.cyan,
          onTap: () => context.push('/custom-words'),
        ),
        const SizedBox(height: 12),
        _TrainingGameRow(
          icon: Icons.article_outlined,
          title: l10n.trainingPassageCloze,
          subtitle: l10n.trainingPassageClozeDesc,
          color: AppTheme.leaf,
          onTap: null,
        ),
        const SizedBox(height: 12),
        _TrainingGameRow(
          icon: Icons.hearing_outlined,
          title: l10n.trainingListening,
          subtitle: l10n.trainingListeningDesc,
          color: AppTheme.mango,
          onTap: null,
        ),
        const SizedBox(height: 22),
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

class _TrainingGameList extends StatelessWidget {
  const _TrainingGameList({required this.children});

  final List<_TrainingGameRow> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index < children.length - 1) const SizedBox(width: 12),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (onTap == null) ...[
                  const SizedBox(height: 10),
                  PillLabel(
                    label: 'Coming Soon',
                    icon: Icons.lock_clock_outlined,
                    color: Colors.blueGrey,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
    return Row(
      children: [
        Expanded(
          child: _TrainingSignal(
            label: l10n.trainingDueWords,
            value: '$dueWords',
            icon: Icons.today_outlined,
            color: AppTheme.teal,
          ),
        ),
        const _TrainingSignalDivider(),
        Expanded(
          child: _TrainingSignal(
            label: l10n.trainingWeakWords,
            value: '$weakWords',
            icon: Icons.warning_amber_outlined,
            color: AppTheme.coral,
          ),
        ),
        const _TrainingSignalDivider(),
        Expanded(
          child: _TrainingSignal(
            label: l10n.trainingComboTarget,
            value: '$comboTarget',
            icon: Icons.bolt,
            color: AppTheme.mango,
          ),
        ),
      ],
    );
  }
}

class _TrainingSignal extends StatelessWidget {
  const _TrainingSignal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainingSignalDivider extends StatelessWidget {
  const _TrainingSignalDivider();

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
