import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';

class ForumComposeScreen extends ConsumerStatefulWidget {
  const ForumComposeScreen({super.key});

  @override
  ConsumerState<ForumComposeScreen> createState() => _ForumComposeScreenState();
}

class _ForumComposeScreenState extends ConsumerState<ForumComposeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController(text: '今日打卡');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: const Text('发布帖子'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: '社区发帖',
              subtitle: '发布学习打卡、错题讨论或方法复盘，内容会写入服务器论坛记录。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '标题',
                prefixIcon: Icon(Icons.title_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 5,
              maxLines: 9,
              decoration: const InputDecoration(
                labelText: '正文',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: '标签，用逗号分隔',
                prefixIcon: Icon(Icons.tag_outlined),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSubmitting ? '发布中' : '发布'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('标题和正文都需要填写')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final post = await ref
          .read(appServicesRepositoryProvider)
          .createForumPost(
            title: title,
            content: content,
            tags: _tagController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(),
          );
      ref.invalidate(forumPostsProvider);
      await ref.read(appControllerProvider.notifier).refreshRewardTasks();
      if (!mounted) return;
      context.go('/forum/posts/${post.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('暂时无法发布帖子：$error'),
          backgroundColor: AppTheme.coral,
        ),
      );
    }
  }
}
