import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final posts = [
      _ForumPostData(
        title: l10n.communityPostCheckinTitle,
        tag: l10n.communityPostCheckinTag,
        body: l10n.communityPostCheckinBody,
      ),
      _ForumPostData(
        title: l10n.communityPostAbstractTitle,
        tag: l10n.communityPostMistakeTag,
        body: l10n.communityPostAbstractBody,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: Text(l10n.discoverCommunityPosts),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            for (var index = 0; index < posts.length; index++) ...[
              _ForumPost(post: posts[index]),
              if (index != posts.length - 1)
                const SizedBox(height: AppTokens.s12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForumPost extends StatelessWidget {
  const _ForumPost({required this.post});

  final _ForumPostData post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPill(
            label: post.tag,
            variant: PillVariant.streak,
            icon: Icons.tag_outlined,
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.s4),
              Text(
                '24',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppTokens.s16),
              Icon(
                Icons.mode_comment_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.s4),
              Text(
                '6',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForumPostData {
  const _ForumPostData({
    required this.title,
    required this.tag,
    required this.body,
  });

  final String title;
  final String tag;
  final String body;
}
