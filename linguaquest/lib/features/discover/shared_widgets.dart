import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../l10n/generated/app_localizations.dart';

class RewardTaskList extends StatelessWidget {
  const RewardTaskList({super.key, required this.tasks});

  final List<RewardTaskData> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < tasks.length; index++) ...[
          RewardTaskRow(task: tasks[index]),
          if (index != tasks.length - 1)
            Divider(
              height: 10,
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class RewardTaskRow extends StatelessWidget {
  const RewardTaskRow({super.key, required this.task});

  final RewardTaskData task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canClaim = task.isDone && !task.isClaimed;
    final activeColor = canClaim
        ? AppTheme.teal
        : task.isDone
        ? AppTheme.success
        : AppTheme.mango;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canClaim
            ? task.onClaim
            : task.isDone
            ? null
            : task.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(task.icon, color: activeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      task.condition,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PillLabel(
                    label: task.isClaimed
                        ? l10n.discoverClaimed(task.points.toString())
                        : canClaim
                        ? l10n.discoverClaim(task.points.toString())
                        : l10n.discoverGoComplete(task.points.toString()),
                    icon: task.isDone
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RewardTaskData {
  const RewardTaskData({
    required this.icon,
    required this.title,
    required this.condition,
    required this.points,
    required this.isDone,
    required this.isClaimed,
    required this.onTap,
    required this.onClaim,
  });

  final IconData icon;
  final String title;
  final String condition;
  final int points;
  final bool isDone;
  final bool isClaimed;
  final VoidCallback onTap;
  final VoidCallback onClaim;
}
