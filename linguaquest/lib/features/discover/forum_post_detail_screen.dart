import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/forum_post.dart';

class ForumPostDetailScreen extends ConsumerStatefulWidget {
  const ForumPostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<ForumPostDetailScreen> createState() =>
      _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends ConsumerState<ForumPostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(forumPostDetailProvider(widget.postId));
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: const Text('帖子详情'),
      ),
      body: SafeArea(
        child: detail.when(
          data: (value) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _PostHeader(post: value.post, onLike: _likePost),
              const SizedBox(height: 20),
              const SectionHeader(title: '评论', subtitle: '围绕学习方法和错题讨论。'),
              const SizedBox(height: 12),
              if (value.comments.isEmpty)
                Text(
                  '还没有评论，写下第一个学习建议。',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final comment in value.comments)
                  _CommentRow(comment: comment),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '写评论',
                  prefixIcon: Icon(Icons.mode_comment_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _isWorking ? null : _sendComment,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_isWorking ? '提交中' : '发表评论'),
                ),
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '暂时无法同步帖子详情，请稍后重试。',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _likePost() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await ref
          .read(appServicesRepositoryProvider)
          .likeForumPost(widget.postId);
      ref.invalidate(forumPostDetailProvider(widget.postId));
      ref.invalidate(forumPostsProvider);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isWorking = true);
    try {
      await ref
          .read(appServicesRepositoryProvider)
          .addForumComment(postId: widget.postId, content: content);
      _commentController.clear();
      ref.invalidate(forumPostDetailProvider(widget.postId));
      ref.invalidate(forumPostsProvider);
      await ref.read(appControllerProvider.notifier).refreshRewardTasks();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.onLike});

  final ForumPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in post.tags)
              PillLabel(
                label: tag,
                icon: Icons.tag_outlined,
                color: AppTheme.coral,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(post.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${post.authorName} · ${_timeLabel(post.createdAt)}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text(post.content, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
              label: Text('${post.likeCount} 赞'),
              onPressed: onLike,
            ),
            TextButton.icon(
              onPressed: null,
              icon: const Icon(Icons.mode_comment_outlined, size: 18),
              label: Text('${post.commentCount} 评论'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final ForumComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(icon: Icons.person_outline, color: AppTheme.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(comment.content),
                const SizedBox(height: 4),
                Text(
                  _timeLabel(comment.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _timeLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}
