import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../data/models/ai_feature.dart';
import '../../l10n/generated/app_localizations.dart';

class AiSentenceAnalysisScreen extends ConsumerStatefulWidget {
  const AiSentenceAnalysisScreen({super.key});

  @override
  ConsumerState<AiSentenceAnalysisScreen> createState() =>
      _AiSentenceAnalysisScreenState();
}

class _AiSentenceAnalysisScreenState
    extends ConsumerState<AiSentenceAnalysisScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _errorMessage;

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
        .askAi(
          featureType: 'sentence_analysis',
          prompt: _controller.text.trim(),
        );
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
        (s) => s.aiHistory
            .where((e) => e.featureType == 'sentence_analysis')
            .toList(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Sentence Analysis'),
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
                    'Enter a sentence to analyze',
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
                      hintText: 'Type or paste an English sentence...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a sentence';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading ? 'Analyzing...' : 'Analyze',
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
                  l10n.aiEmptyAnalysis(language),
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
              _AnalysisResultCard(result: _result!),
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
                  child: _AnalysisHistoryCard(
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

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainClause = result['mainClause'] as String? ?? '';
    final translation = result['translation'] as String? ?? '';
    final clauses =
        (result['clauses'] as List<dynamic>?)?.cast<String>() ?? [];
    final modifiers =
        (result['modifiers'] as List<dynamic>?)?.cast<String>() ?? [];
    final vocabNotes =
        (result['vocabularyNotes'] as List<dynamic>?)?.cast<String>() ?? [];

    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Result',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          _Section(label: 'Main Clause', content: mainClause),
          if (clauses.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _Section(label: 'Clauses', content: clauses.join('\n')),
          ],
          if (modifiers.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _Section(label: 'Modifiers', content: modifiers.join('\n')),
          ],
          const SizedBox(height: AppTokens.s8),
          _Section(label: 'Translation', content: translation),
          if (vocabNotes.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _Section(label: 'Vocabulary Notes', content: vocabNotes.join('\n')),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.content});

  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(content, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _AnalysisHistoryCard extends StatelessWidget {
  const _AnalysisHistoryCard({required this.entry, required this.onDelete});

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
              entry.response['mainClause'] as String? ?? '',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
