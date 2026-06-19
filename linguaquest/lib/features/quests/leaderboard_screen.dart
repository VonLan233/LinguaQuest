import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/analytics.dart';
import '../../l10n/generated/app_localizations.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _dimensions = ['global', 'friends', 'class'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appControllerProvider.notifier)
          .refreshLeaderboard(dimension: 'global');
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final dimension = _dimensions[_tabController.index];
    ref
        .read(appControllerProvider.notifier)
        .refreshLeaderboard(dimension: dimension);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final leaderboard = state.leaderboardSnapshot;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: Text(l10n.questLeaderboard),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
            Tab(text: 'Class'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: List.generate(3, (i) {
            final dimension = _dimensions[i];
            if (leaderboard == null || leaderboard.dimension != dimension) {
              return const Center(child: CircularProgressIndicator());
            }
            if (leaderboard.entries.isEmpty) {
              return MascotEmptyState(
                title: l10n.leaderboardEmptyTitle,
                message: l10n.leaderboardEmptyBody,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionHeader(
                  title: l10n.leaderboardTitle,
                  subtitle: 'Rank: #${leaderboard.currentUserRank}',
                ),
                const SizedBox(height: 16),
                for (final entry in leaderboard.entries)
                  _LeaderboardTile(entry: entry, theme: theme),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.theme});

  final LeaderboardEntry entry;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    final radius = BorderRadius.circular(16);
    final content = Row(
      children: [
        CircleAvatar(
          backgroundColor: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isMe
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
          child: Text('#${entry.rank}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                  color: isMe ? AppTokens.primarySoftText : null,
                ),
              ),
              if (isMe)
                Text(
                  "That's you!",
                  style: TextStyle(
                    color: AppTokens.primarySoftText,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        AppPill(label: '${entry.xp} XP', variant: PillVariant.xp),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isMe
          ? Container(
              decoration: BoxDecoration(
                color: AppTokens.primarySoft,
                borderRadius: radius,
                border: Border.all(
                  color: AppTokens.primarySoftText.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: content,
            )
          : AppCard(child: content),
    );
  }
}
