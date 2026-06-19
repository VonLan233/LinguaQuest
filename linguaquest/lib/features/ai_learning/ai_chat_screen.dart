import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/ai_feature.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.word, this.example});

  final String? word;
  final String? example;

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.word != null && widget.word!.isNotEmpty) {
      _controller.text = 'What does "${widget.word}" mean?';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });
    try {
      final result = await ref
          .read(appControllerProvider.notifier)
          .askAi(featureType: 'chat', prompt: _controller.text.trim());
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(
      appControllerProvider.select(
        (s) =>
            s.aiHistory.where((e) => e.featureType == 'chat').toList(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Q&A'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
            88,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask a question',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: _controller,
                    maxLength: 2000,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type your question about English...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a question';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading ? 'Asking...' : 'Ask',
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: AppTokens.s20),
              _AiChatResultCard(result: _result!),
            ],
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s24),
              Text(
                'History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              ...history.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s8),
                  child: _AiHistoryCard(
                    entry: entry,
                    onDelete: () => ref
                        .read(appControllerProvider.notifier)
                        .deleteAiHistory(entry.id),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiChatResultCard extends StatelessWidget {
  const _AiChatResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = result['answer'] as String? ?? '';
    final cautions =
        (result['cautions'] as List<dynamic>?)?.cast<String>() ?? [];
    final relatedWords =
        (result['relatedWords'] as List<dynamic>?)?.cast<String>() ?? [];

    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18),
              const SizedBox(width: AppTokens.s8),
              Text(
                'Answer',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(answer),
          if (cautions.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              'Cautions',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            ...cautions.map((c) => Text('• $c')),
          ],
          if (relatedWords.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              'Related Words',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s4,
              children: relatedWords
                  .map(
                    (w) => AppPill(
                      label: w,
                      variant: PillVariant.primary,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiHistoryCard extends StatelessWidget {
  const _AiHistoryCard({required this.entry, required this.onDelete});

  final AiHistoryEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: () => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.prompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              entry.response['answer'] as String? ?? '',
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
