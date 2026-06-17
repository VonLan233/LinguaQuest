import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../l10n/generated/app_localizations.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        88,
      ),
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            AppPill(
              label: '${user?.xp ?? 0} ${l10n.commonXP}',
              icon: Icons.bolt,
              variant: PillVariant.xp,
            ),
            AppPill(
              label: '${user?.streak ?? 0} ${l10n.homeStreakLabel}',
              icon: Icons.local_fire_department_outlined,
              variant: PillVariant.streak,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s32),
        Row(
          children: [
            Expanded(
              child: _DiscoverNavCard(
                icon: Icons.emoji_events_outlined,
                title: l10n.discoverXpTasks,
                subtitle: l10n.discoverXpTasksSubtitle,
                color: AppTokens.xpSoftText,
                onTap: () => context.push('/discover/xp-tasks'),
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: _DiscoverNavCard(
                icon: Icons.card_giftcard_outlined,
                title: l10n.discoverLuckyDraw,
                subtitle: l10n.discoverLuckyDrawSubtitle,
                color: AppTokens.streakSoftText,
                onTap: () => context.push('/discover/lucky-draw'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        _DiscoverNavCard(
          icon: Icons.forum_outlined,
          title: l10n.discoverCommunityPosts,
          subtitle: l10n.discoverCommunityPostsSubtitle,
          color: AppTokens.successSoftText,
          onTap: () => context.push('/discover/community'),
        ),
      ],
    );
  }
}

class _DiscoverNavCard extends StatelessWidget {
  const _DiscoverNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: AppTokens.s12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
