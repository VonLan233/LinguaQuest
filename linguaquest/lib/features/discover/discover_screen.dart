import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../l10n/generated/app_localizations.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: '${user?.xp ?? 0} ${l10n.commonXP}',
              icon: Icons.bolt,
              color: AppTheme.mango,
            ),
            PillLabel(
              label: '${user?.streak ?? 0} ${l10n.homeStreakLabel}',
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _DiscoverNavCard(
                icon: Icons.emoji_events_outlined,
                title: l10n.discoverXpTasks,
                subtitle: l10n.discoverXpTasksSubtitle,
                color: AppTheme.mango,
                onTap: () => context.push('/discover/xp-tasks'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DiscoverNavCard(
                icon: Icons.card_giftcard_outlined,
                title: l10n.discoverLuckyDraw,
                subtitle: l10n.discoverLuckyDrawSubtitle,
                color: AppTheme.coral,
                onTap: () => context.push('/discover/lucky-draw'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DiscoverNavCard(
          icon: Icons.forum_outlined,
          title: l10n.discoverCommunityPosts,
          subtitle: l10n.discoverCommunityPostsSubtitle,
          color: AppTheme.cyan,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
