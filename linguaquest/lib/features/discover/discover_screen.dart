import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/compact_entry_card.dart';
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
              icon: AppIcons.bolt,
              variant: PillVariant.xp,
            ),
            AppPill(
              label: '${user?.streak ?? 0} ${l10n.homeStreakLabel}',
              icon: AppIcons.localFireDepartment,
              variant: PillVariant.streak,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s32),
        CompactEntryCard(
          icon: AppIcons.autoStories,
          title: l10n.readingDiscoverEntry,
          color: AppTokens.primarySoftText,
          onTap: () => context.push('/reading'),
        ),
        const SizedBox(height: AppTokens.s12),
        CompactEntryCard(
          icon: AppIcons.emojiEvents,
          title: l10n.discoverXpTasks,
          color: AppTokens.xpSoftText,
          onTap: () => context.push('/discover/xp-tasks'),
        ),
        const SizedBox(height: AppTokens.s12),
        CompactEntryCard(
          icon: AppIcons.cardGiftcard,
          title: l10n.discoverLuckyDraw,
          color: AppTokens.streakSoftText,
          onTap: () => context.push('/discover/lucky-draw'),
        ),
        const SizedBox(height: AppTokens.s12),
        CompactEntryCard(
          icon: AppIcons.forum,
          title: l10n.discoverCommunityPosts,
          color: AppTokens.successSoftText,
          onTap: () => context.push('/discover/community'),
        ),
        const SizedBox(height: AppTokens.s12),
        CompactEntryCard(
          icon: AppIcons.bookmark,
          title: l10n.discoverMyFavorites,
          color: AppTokens.successSoftText,
          onTap: () => context.push('/forum/favorites'),
        ),
      ],
    );
  }
}
