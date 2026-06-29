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
import '../reading/reading_labels.dart';

/// The ordered list of filter options. 'All' is the sentinel for "no filter".
const _kFilterOptions = [
  'All',
  'Grammar',
  'Vocabulary',
  'Culture',
  'General',
  'Progress',
];

/// Map raw English tag → [PillVariant] for the card badge.
PillVariant _tagVariant(String tag) {
  switch (tag) {
    case 'Grammar':
      return PillVariant.primary;
    case 'Vocabulary':
      return PillVariant.xp;
    case 'Culture':
      return PillVariant.streak;
    case 'Progress':
      return PillVariant.success;
    case 'General':
      return PillVariant.success;
    default:
      // §8 (P4f): scope tags (e.g. "HSK 4" / "JLPT N5") and any other free-form
      // tag get a neutral-primary badge.
      return PillVariant.primary;
  }
}

/// Returns the localized display label for a raw English tag.
String _tagLabel(AppLocalizations l10n, String tag) {
  switch (tag) {
    case 'Grammar':
      return l10n.communityTagGrammar;
    case 'Vocabulary':
      return l10n.communityTagVocabulary;
    case 'Culture':
      return l10n.communityTagCulture;
    case 'Progress':
      return l10n.communityTagProgress;
    case 'General':
      return l10n.communityTagGeneral;
    default:
      // §8 (P4f): scope tags (e.g. "HSK 4" / "JLPT N5") are already
      // display-ready — show them verbatim.
      return tag;
  }
}

/// Returns a localized relative-time string for [createdAt].
String _relativeTime(AppLocalizations l10n, DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return l10n.communityTimeJustNow;
  if (diff.inHours < 1) return l10n.communityTimeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.communityTimeHoursAgo(diff.inHours);
  if (diff.inDays <= 7) return l10n.communityTimeDaysAgo(diff.inDays);
  // Fall back to a short ISO date for posts older than a week.
  final d = createdAt;
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedFilter = 'All';

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
    // §8 (P4f): include the user's current learning scope (e.g. "HSK 4" /
    // "JLPT N5") as a filter option alongside the fixed topic tags.
    final scopeTag = ref.watch(
      appControllerProvider.select(
        (s) => readingLevelLabel(s.currentLanguage, s.currentWordBookId),
      ),
    );
    final filterOptions = [
      ..._kFilterOptions,
      if (!_kFilterOptions.contains(scopeTag)) scopeTag,
    ];

    final displayedPosts = _selectedFilter == 'All'
        ? posts
        : posts.where((p) => p.tag == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: Text(l10n.discoverCommunityPosts),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/forum/compose'),
        tooltip: l10n.communityNewPost,
        child: const Icon(Icons.edit_rounded),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter chip row ────────────────────────────────────────────
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
                children: [
                  for (final option in filterOptions) ...[
                    ChoiceChip(
                      label: Text(
                        option == 'All'
                            ? l10n.communityFilterAll
                            : _tagLabel(l10n, option),
                      ),
                      selected: _selectedFilter == option,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = option),
                    ),
                    const SizedBox(width: AppTokens.s8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s12),

            // ── Post list / empty states ───────────────────────────────────
            Expanded(
              child: displayedPosts.isEmpty
                  ? MascotEmptyState(
                      title: _selectedFilter == 'All'
                          ? 'No posts yet'
                          : l10n.communityNoPostsInFilter,
                      message: _selectedFilter == 'All'
                          ? 'Be the first to share something with the community!'
                          : l10n.communityNoPostsInFilter,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s20,
                        0,
                        AppTokens.s20,
                        88,
                      ),
                      itemCount: displayedPosts.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: AppTokens.s12),
                      itemBuilder: (context, index) =>
                          _ForumPostCard(post: displayedPosts[index]),
                    ),
            ),
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
    final l10n = AppLocalizations.of(context);

    return AppCard(
      onTap: () => context.push('/forum/posts/${post.id}'),
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: avatar + author + relative time ───────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    _AuthorAvatar(name: post.authorName),
                    const SizedBox(width: AppTokens.s8),
                    Flexible(
                      child: Text(
                        post.authorName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                _relativeTime(l10n, post.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),

          // ── Tag badge ─────────────────────────────────────────────────
          AppPill(
            label: _tagLabel(l10n, post.tag),
            variant: _tagVariant(post.tag),
            icon: AppIcons.tag,
          ),
          const SizedBox(height: AppTokens.s12),

          // ── Title ─────────────────────────────────────────────────────
          Text(
            post.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.s8),

          // ── Body preview ─────────────────────────────────────────────
          Text(
            post.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.s12),

          // ── Footer counts ─────────────────────────────────────────────
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
    );
  }
}

/// Generates a 28-dp circle avatar from the author's display name.
/// Background color is derived from the name's hash for stable identity.
/// ponytail: hash-based color; replace with real avatar URL if added later.
class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final hue = (name.hashCode % 360).abs().toDouble();
    final bg = HSLColor.fromAHSL(1, hue, 0.45, 0.45).toColor();
    return CircleAvatar(
      radius: 14,
      backgroundColor: bg,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.76,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
