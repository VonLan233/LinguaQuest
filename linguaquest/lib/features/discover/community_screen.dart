import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../data/models/forum.dart';
import '../../l10n/generated/app_localizations.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).refreshForumPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final posts = ref.watch(
      appControllerProvider.select((s) => s.forumPosts),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: Text(l10n.discoverCommunityPosts),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/forum/compose'),
        child: const Icon(Icons.edit_rounded),
      ),
      body: SafeArea(
        child: posts.isEmpty
            ? const MascotEmptyState(
                title: 'No posts yet',
                message:
                    'Be the first to share something with the community!',
              )
            : ListView(
                padding: const EdgeInsets.all(AppTokens.s20),
                children: [
                  for (var index = 0; index < posts.length; index++) ...[
                    _ForumPostCard(post: posts[index]),
                    if (index != posts.length - 1)
                      const SizedBox(height: AppTokens.s12),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/forum/posts/${post.id}'),
      child: AppCard(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPill(
              label: post.tag,
              variant: PillVariant.streak,
              icon: AppIcons.tag,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              post.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Icon(
                  AppIcons.thumbUpAlt,
                  size: 18,
                  color: post.isLiked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.s4),
                Text(
                  '${post.likeCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppTokens.s16),
                Icon(
                  AppIcons.modeComment,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.s4),
                Text(
                  '${post.commentCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
