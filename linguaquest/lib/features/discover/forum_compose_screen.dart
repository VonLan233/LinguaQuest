import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

const _kTags = ['Grammar', 'Vocabulary', 'Culture', 'General', 'Progress'];

class ForumComposeScreen extends ConsumerStatefulWidget {
  const ForumComposeScreen({super.key});

  @override
  ConsumerState<ForumComposeScreen> createState() => _ForumComposeScreenState();
}

class _ForumComposeScreenState extends ConsumerState<ForumComposeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTag = 'General';
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title.');
      return;
    }
    if (body.isEmpty) {
      setState(() => _errorMessage = 'Please enter some content.');
      return;
    }
    if (title.length > 200) {
      setState(() => _errorMessage = 'Title must be under 200 characters.');
      return;
    }
    if (body.length > 5000) {
      setState(
        () => _errorMessage = 'Content must be under 5000 characters.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final post = await ref
          .read(appControllerProvider.notifier)
          .createForumPost(title: title, body: body, tag: _selectedTag);
      if (!mounted) return;
      if (post != null) {
        context.pop();
      } else {
        setState(
          () => _errorMessage = 'Failed to publish post. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover/community'),
        title: Text(l10n.communityNewPost),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            // Title field
            Text(
              'Title',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            TextField(
              controller: _titleController,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What is your question or topic?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.s16),

            // Tag selector
            Text(
              'Tag',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Wrap(
              spacing: AppTokens.s8,
              children: [
                for (final tag in _kTags)
                  ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (_) => setState(() => _selectedTag = tag),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.s16),

            // Body field
            Text(
              'Content',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            TextField(
              controller: _bodyController,
              maxLength: 5000,
              maxLines: 8,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Share your question, tips, or story...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppTokens.s8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: AppTokens.s24),
            AppPrimaryButton(
              label: _submitting ? 'Publishing...' : 'Publish',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
