import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../l10n/generated/app_localizations.dart';

class RewardTaskList extends StatelessWidget {
  const RewardTaskList({super.key, required this.tasks});

  final List<RewardTaskData> tasks;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < tasks.length; index++) ...[
            RewardTaskRow(task: tasks[index]),
            if (index != tasks.length - 1)
              const Divider(height: AppTokens.s16, color: AppTokens.hairline),
          ],
        ],
      ),
    );
  }
}

class RewardTaskRow extends StatelessWidget {
  const RewardTaskRow({super.key, required this.task});

  final RewardTaskData task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final canClaim = task.isDone && !task.isClaimed;
    final accent = canClaim
        ? AppTokens.azure
        : task.isDone
        ? AppTokens.successColor(context)
        : AppTokens.mangoColor(context);

    final String badgeLabel;
    final PillVariant badgeVariant;
    final IconData badgeIcon;
    if (task.isClaimed) {
      badgeLabel = l10n.discoverClaimed(task.points.toString());
      badgeVariant = PillVariant.success;
      badgeIcon = Icons.check_circle_outline;
    } else if (canClaim) {
      badgeLabel = l10n.discoverClaim(task.points.toString());
      badgeVariant = PillVariant.primary;
      badgeIcon = Icons.add_circle_outline;
    } else {
      badgeLabel = l10n.discoverGoComplete(task.points.toString());
      badgeVariant = PillVariant.streak;
      badgeIcon = Icons.add_circle_outline;
    }

    return InkWell(
      onTap: canClaim
          ? task.onClaim
          : task.isDone
          ? null
          : task.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s16,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              alignment: Alignment.center,
              child: Icon(task.icon, size: 22, color: accent),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s2),
                  Text(
                    task.condition,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppPill(
                  label: badgeLabel,
                  variant: badgeVariant,
                  icon: badgeIcon,
                ),
              ),
            ),
          ],
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
