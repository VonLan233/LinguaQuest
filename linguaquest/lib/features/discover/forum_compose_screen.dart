import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../reading/reading_labels.dart';

const _kTags = ['Grammar', 'Vocabulary', 'Culture', 'General', 'Progress'];

class ForumComposeScreen extends ConsumerStatefulWidget {
  const ForumComposeScreen({super.key});

  @override
  ConsumerState<ForumComposeScreen> createState() => _ForumComposeScreenState();
}

class _ForumComposeScreenState extends ConsumerState<ForumComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTag = 'General';
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    setState(() => _submitting = true);
    try {
      final post = await ref
          .read(appControllerProvider.notifier)
          .createForumPost(title: title, body: body, tag: _selectedTag);
      if (!mounted) return;
      if (post != null) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish post. Please try again.'),
          ),
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
    // §8 (P4f): offer the user's current learning scope as a one-tap tag
    // (e.g. "HSK 4" / "JLPT N5"), in addition to the fixed topic tags.
    final scopeTag = ref.watch(
      appControllerProvider.select(
        (s) => readingLevelLabel(s.currentLanguage, s.currentWordBookId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(
          fallbackLocation: '/discover/community',
        ),
        title: Text(l10n.communityNewPost),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What is your question or topic?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Please enter a title.';
                  if (v.length > 200) {
                    return 'Title must be under 200 characters.';
                  }
                  return null;
                },
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
                  ChoiceChip(
                    key: const ValueKey('compose-scope-chip'),
                    label: Text(scopeTag),
                    selected: _selectedTag == scopeTag,
                    onSelected: (_) => setState(() => _selectedTag = scopeTag),
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
              TextFormField(
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
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Please enter some content.';
                  if (v.length > 5000) {
                    return 'Content must be under 5000 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTokens.s24),
              AppPrimaryButton(
                label: _submitting ? 'Publishing...' : 'Publish',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
