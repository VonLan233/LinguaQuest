import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../data/models/ai_feature.dart';

class AiWritingReviewScreen extends ConsumerStatefulWidget {
  const AiWritingReviewScreen({super.key});

  @override
  ConsumerState<AiWritingReviewScreen> createState() =>
      _AiWritingReviewScreenState();
}

class _AiWritingReviewScreenState
    extends ConsumerState<AiWritingReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _essayController = TextEditingController();
  String _selectedExamType = 'General';
  bool _isLoading = false;
  WritingReviewResult? _result;
  bool _showRewrite = false;

  static const _examTypes = [
    'General',
    'IELTS',
    'CET-4',
    'CET-6',
    'TOEFL',
  ];

  @override
  void dispose() {
    _essayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });
    final raw = await ref.read(appControllerProvider.notifier).reviewWriting(
      essay: _essayController.text.trim(),
      examType:
          _selectedExamType == 'General' ? null : _selectedExamType,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (raw.isNotEmpty) {
          _result = WritingReviewResult.fromJson(raw);
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _showRewrite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Writing Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_result != null)
            TextButton(onPressed: _reset, child: const Text('New Essay')),
        ],
      ),
      body: SafeArea(
        child: _result != null
            ? _ResultView(
                result: _result!,
                showRewrite: _showRewrite,
                onToggleRewrite: () =>
                    setState(() => _showRewrite = !_showRewrite),
              )
            : _InputView(
                formKey: _formKey,
                essayController: _essayController,
                examTypes: _examTypes,
                selectedExamType: _selectedExamType,
                onExamTypeChanged: (v) =>
                    setState(() => _selectedExamType = v),
                isLoading: _isLoading,
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ── Input Phase ───────────────────────────────────────────────────────────────

class _InputView extends StatelessWidget {
  const _InputView({
    required this.formKey,
    required this.essayController,
    required this.examTypes,
    required this.selectedExamType,
    required this.onExamTypeChanged,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController essayController;
  final List<String> examTypes;
  final String selectedExamType;
  final ValueChanged<String> onExamTypeChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.s20),
        children: [
          // Exam type selector
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam Type',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: examTypes.map((type) {
                    final selected = type == selectedExamType;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) => onExamTypeChanged(type),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          // Essay input
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Essay',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: essayController,
                  builder: (context, value, _) {
                    return Text(
                      '${value.text.length} / 3000 characters',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: value.text.length > 3000
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTokens.s8),
                TextFormField(
                  controller: essayController,
                  maxLines: null,
                  minLines: 8,
                  maxLength: 3000,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  decoration: const InputDecoration(
                    hintText:
                        'Paste or type your essay here (50–3000 characters)...',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 50) {
                      return 'Essay must be at least 50 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s24),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            AppPrimaryButton(
              label: 'Submit for Review',
              onPressed: onSubmit,
            ),
        ],
      ),
    );
  }
}

// ── Result Phase ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.showRewrite,
    required this.onToggleRewrite,
  });

  final WritingReviewResult result;
  final bool showRewrite;
  final VoidCallback onToggleRewrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppTokens.s20),
      children: [
        // Total score
        AppCard(
          child: Column(
            children: [
              Text(
                'Overall Score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              AppPill(
                label: '${result.totalScore} / 100',
                variant: PillVariant.xp,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        // Rubric scores
        if (result.rubricScores.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                ...result.rubricScores.entries.map((entry) {
                  const maxScores = {
                    'content': 25,
                    'language': 20,
                    'structure': 20,
                    'vocabulary': 20,
                    'accuracy': 15,
                  };
                  const labels = {
                    'content': 'Content',
                    'language': 'Language',
                    'structure': 'Structure',
                    'vocabulary': 'Vocabulary',
                    'accuracy': 'Accuracy',
                  };
                  final max = maxScores[entry.key] ?? 20;
                  final label = labels[entry.key] ?? entry.key;
                  final ratio = max > 0 ? entry.value / max : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${entry.value}/$max',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.s4),
                        AppProgressBar(value: ratio.clamp(0.0, 1.0)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
        ],
        // Main issues
        if (result.mainIssues.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main Issues',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ...result.mainIssues.map(
                  (issue) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTokens.s4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(issue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
        ],
        // Grammar issues
        if (result.grammarIssues.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grammar Corrections',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ...result.grammarIssues.map((issue) {
                  final original = issue['original'] ?? '';
                  final corrected = issue['corrected'] ?? '';
                  final rule = issue['rule'] ?? '';
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTokens.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(
                            text: original,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const TextSpan(text: '  →  '),
                          TextSpan(
                            text: corrected,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ])),
                        if (rule.isNotEmpty)
                          Text(
                            rule,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
        ],
        // High-score expressions
        if (result.highScoreExpressions.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High-Score Expressions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ...result.highScoreExpressions.map((expr) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      expr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: expr));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!')),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
        ],
        // Paragraph suggestions
        if (result.paragraphSuggestions.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paragraph Suggestions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ...result.paragraphSuggestions.map((s) {
                  final para = s['paragraph'] ?? '';
                  final suggestion = s['suggestion'] ?? '';
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTokens.s4),
                    child: Text('Paragraph $para: $suggestion'),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
        ],
        // Rewritten sample (collapsible)
        if (result.rewrittenSample.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onToggleRewrite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rewritten Sample',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(showRewrite
                          ? Icons.expand_less
                          : Icons.expand_more),
                    ],
                  ),
                ),
                if (showRewrite) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(result.rewrittenSample),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
