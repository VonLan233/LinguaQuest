import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../data/models/ai_feature.dart';
import '../../l10n/generated/app_localizations.dart';

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
  String? _errorMessage;

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
      _errorMessage = null;
    });
    final result = await ref
        .read(appControllerProvider.notifier)
        .askAi(featureType: 'chat', prompt: _controller.text.trim());
    if (mounted) {
      if (result.isEmpty) {
        final errMsg = ref.read(appControllerProvider).errorMessage;
        setState(() {
          _isLoading = false;
          _errorMessage =
              errMsg ?? AppLocalizations.of(context).aiErrorGeneric;
        });
      } else {
        setState(() {
          _isLoading = false;
          _result = result;
          _errorMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final language = languageLabel(
      ref.watch(appControllerProvider.select((s) => s.currentLanguage)),
      l10n,
    );
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
                    decoration: InputDecoration(
                      hintText: l10n.aiQuestionHint(language),
                      border: const OutlineInputBorder(),
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
            // EMPTY state: no result, no error, not loading
            if (_result == null && _errorMessage == null && !_isLoading) ...[
              const SizedBox(height: AppTokens.s20),
              AppCard(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Text(
                  l10n.aiEmptyChat(language),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            // ERROR state
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTokens.s20),
              AiErrorCard(
                message: _errorMessage!,
                onRetry: _submit,
              ),
            ],
            // RESULT state
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
