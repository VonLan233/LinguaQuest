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

class ForumPostDetailScreen extends ConsumerStatefulWidget {
  const ForumPostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<ForumPostDetailScreen> createState() =>
      _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends ConsumerState<ForumPostDetailScreen> {
  final _commentController = TextEditingController();
  List<ForumComment> _comments = [];
  bool _loadingComments = true;
  bool _submitting = false;

  ForumPost? _post;
  bool _loadingPost = true;
  bool _postNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final repo = ref.read(forumRepositoryProvider);
      final post = await repo.getPost(widget.postId);
      if (mounted) setState(() { _post = post; _loadingPost = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingPost = false; _postNotFound = true; });
    }
  }

  Future<void> _loadComments() async {
    try {
      final repo = ref.read(forumRepositoryProvider);
      final comments = await repo.listComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final comment = await ref
          .read(appControllerProvider.notifier)
          .createForumComment(postId: widget.postId, body: text);
      if (comment != null && mounted) {
        _commentController.clear();
        setState(() {
          _comments = [..._comments, comment];
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showReportSheet(BuildContext context, String postId) {
    const reasons = ['Spam', 'Inappropriate', 'Other'];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s20,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Text(
                'Report post',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final reason in reasons)
              ListTile(
                title: Text(reason),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _submitReport(postId, reason);
                },
              ),
            const SizedBox(height: AppTokens.s8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String postId, String reason) async {
    try {
      await ref
          .read(appControllerProvider.notifier)
          .reportForumPost(postId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPost) {
      return Scaffold(
        appBar: AppBar(
          leading: const FallbackBackButton(fallbackLocation: '/discover/community'),
          title: const Text('Post'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_postNotFound || _post == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const FallbackBackButton(fallbackLocation: '/discover/community'),
          title: const Text('Post'),
        ),
        body: const MascotEmptyState(
          title: 'Post not found',
          message: 'This post may have been removed.',
        ),
      );
    }
    // Watch live post from controller state (covers Community entry path).
    // Falls back to _post snapshot when the post is not in forumPosts
    // (e.g. navigated from My Favorites before Community list is loaded).
    final ForumPost? livePost = ref.watch(
      appControllerProvider.select((s) {
        for (final p in s.forumPosts) {
          if (p.id == widget.postId) return p;
        }
        return null;
      }),
    );
    final post = livePost ?? _post!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover/community'),
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: Icon(
              post.isLiked ? AppIcons.thumbUpAlt : AppIcons.thumbUpOffAlt,
              color: post.isLiked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              // Optimistic local update so the icon refreshes even when this
              // post is not in forumPosts (e.g. entered from My Favorites).
              setState(() {
                _post = _post!.copyWith(
                  isLiked: !_post!.isLiked,
                  likeCount: _post!.isLiked
                      ? (_post!.likeCount - 1).clamp(0, 999999)
                      : _post!.likeCount + 1,
                );
              });
              ref
                  .read(appControllerProvider.notifier)
                  .toggleForumLike(widget.postId);
            },
          ),
          IconButton(
            icon: Icon(
              post.isFavorited ? AppIcons.bookmark : AppIcons.bookmarkBorder,
              color: post.isFavorited
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              // Optimistic local update (same reason as like above).
              setState(() {
                _post = _post!.copyWith(isFavorited: !_post!.isFavorited);
              });
              ref
                  .read(appControllerProvider.notifier)
                  .toggleForumFavorite(widget.postId);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'report') {
                _showReportSheet(context, widget.postId);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.s16),
              children: [
                _PostBody(post: post),
                const SizedBox(height: AppTokens.s20),
                Text(
                  'Comments (${_comments.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                if (_loadingComments)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTokens.s20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.s16,
                    ),
                    child: Text(
                      'No comments yet. Be the first to reply!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final comment in _comments) ...[
                    _CommentCard(comment: comment),
                    const SizedBox(height: AppTokens.s8),
                  ],
              ],
            ),
          ),
          _CommentInputBar(
            controller: _commentController,
            submitting: _submitting,
            onSend: _submitComment,
          ),
        ],
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorInitial = post.authorName.trim().isEmpty
        ? '?'
        : post.authorName.trim()[0].toUpperCase();
    final authorAvatarBg = HSLColor.fromAHSL(
      1,
      (post.authorName.hashCode % 360).abs().toDouble(),
      0.45,
      0.45,
    ).toColor();
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${post.authorId}'),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: authorAvatarBg,
                  child: Text(
                    authorInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Text(
                  post.authorName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s12),
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
          Text(post.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              Icon(
                AppIcons.thumbUpAlt,
                size: 16,
                color: post.isLiked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.s4),
              Text(
                '${post.likeCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Icon(
                AppIcons.modeComment,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.s4),
              Text(
                '${post.commentCount}',
                style: theme.textTheme.bodySmall?.copyWith(
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

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final ForumComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${comment.authorId}'),
            child: Text(
              comment.authorName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(comment.body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.submitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s8,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 5000,
                buildCounter: (context,
                    {required currentLength,
                    required isFocused,
                    required maxLength}) =>
                    null,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                    vertical: AppTokens.s8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            submitting
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
          ],
        ),
      ),
    );
  }
}
