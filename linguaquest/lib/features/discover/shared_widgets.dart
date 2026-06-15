import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/quest_list_row.dart';
import '../../core/widgets/quest_panel.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';

class RewardTaskList extends StatelessWidget {
  const RewardTaskList({super.key, required this.tasks});

  final List<RewardTaskData> tasks;

  @override
  Widget build(BuildContext context) {
    return QuestPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s4,
      ),
      child: Column(
        children: [
          for (var index = 0; index < tasks.length; index++) ...[
            RewardTaskRow(task: tasks[index]),
            if (index != tasks.length - 1)
              Divider(
                height: AppTokens.s8,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.7),
              ),
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
    final l10n = AppLocalizations.of(context);
    final canClaim = task.isDone && !task.isClaimed;
    final accent = canClaim
        ? AppTokens.azure
        : task.isDone
        ? AppTokens.successColor(context)
        : AppTokens.mangoColor(context);

    final String badgeLabel;
    final StatusTone badgeTone;
    final IconData badgeIcon;
    if (task.isClaimed) {
      badgeLabel = l10n.discoverClaimed(task.points.toString());
      badgeTone = StatusTone.success;
      badgeIcon = Icons.check_circle_outline;
    } else if (canClaim) {
      badgeLabel = l10n.discoverClaim(task.points.toString());
      badgeTone = StatusTone.info;
      badgeIcon = Icons.add_circle_outline;
    } else {
      badgeLabel = l10n.discoverGoComplete(task.points.toString());
      badgeTone = StatusTone.warning;
      badgeIcon = Icons.add_circle_outline;
    }

    return QuestListRow(
      icon: task.icon,
      iconColor: accent,
      title: task.title,
      subtitle: task.condition,
      showChevron: false,
      onTap: canClaim
          ? task.onClaim
          : task.isDone
          ? null
          : task.onTap,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: StatusBadge(
            label: badgeLabel,
            tone: badgeTone,
            icon: badgeIcon,
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
