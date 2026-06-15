import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final entries = state.todayTrainingXp > 0
        ? [
            _Entry(
              name: user?.name ?? l10n.leaderboardDefaultName,
              xp: state.todayTrainingXp,
              rank: 1,
            ),
          ]
        : const <_Entry>[];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: Text(l10n.questLeaderboard),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: l10n.leaderboardTitle,
              subtitle: l10n.leaderboardSubtitle,
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const _EmptyTrainingLeaderboard()
            else
              for (var index = 0; index < entries.length; index++)
                _LeaderboardTile(entry: entries[index], rank: index + 1),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrainingLeaderboard extends StatelessWidget {
  const _EmptyTrainingLeaderboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconCueBadge(
          icon: Icons.leaderboard_outlined,
          color: AppTheme.mango,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.leaderboardEmptyTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.leaderboardEmptyBody,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Entry {
  const _Entry({required this.name, required this.xp, required this.rank});

  final String name;
  final int xp;
  final int rank;
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.rank});

  final _Entry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.iconBadgeSurface(context),
            foregroundColor: theme.colorScheme.primary,
            child: Text('$rank'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context).leaderboardOnlyValidXp,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PillLabel(label: '${entry.xp} XP', color: AppTheme.mango),
        ],
      ),
    );
  }
}
