import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../l10n/generated/app_localizations.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
          padding: const EdgeInsets.all(20),
          children: [
            for (var index = 0; index < posts.length; index++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillLabel(
                      label: posts[index].tag,
                      icon: Icons.tag_outlined,
                      color: AppTheme.coral,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      posts[index].title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      posts[index].body,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, size: 18),
                        SizedBox(width: 4),
                        Text('24'),
                        SizedBox(width: 16),
                        Icon(Icons.mode_comment_outlined, size: 18),
                        SizedBox(width: 4),
                        Text('6'),
                      ],
                    ),
                  ],
                ),
              ),
              if (index != posts.length - 1)
                Divider(
                  height: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
            ],
          ],
        ),
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
