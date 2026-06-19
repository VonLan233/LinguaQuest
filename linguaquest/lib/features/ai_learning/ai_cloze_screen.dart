import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/ai_feature.dart';

class AiClozeScreen extends ConsumerStatefulWidget {
  const AiClozeScreen({super.key, this.word});

  final String? word;

  @override
  ConsumerState<AiClozeScreen> createState() => _AiClozeScreenState();
}

class _AiClozeScreenState extends ConsumerState<AiClozeScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  final Map<int, String?> _selectedAnswers = {};
  final Map<int, bool> _answerCorrectness = {};

  @override
  void initState() {
    super.initState();
    if (widget.word != null && widget.word!.isNotEmpty) {
      _controller.text = widget.word!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _result = null;
      _selectedAnswers.clear();
      _answerCorrectness.clear();
    });
    try {
      final result = await ref
          .read(appControllerProvider.notifier)
          .askAi(
            featureType: 'cloze',
            prompt: 'Generate cloze for: ${_controller.text.trim()}',
            targetWord: _controller.text.trim(),
          );
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

  void _selectAnswer(int blankIndex, String selected, String correct) {
    setState(() {
      _selectedAnswers[blankIndex] = selected;
      _answerCorrectness[blankIndex] = selected == correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(
      appControllerProvider.select(
        (s) =>
            s.aiHistory.where((e) => e.featureType == 'cloze').toList(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Cloze Test'),
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
                    'Enter a word for cloze test',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: _controller,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'e.g. abundant, curious...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a word';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading ? 'Generating...' : 'Generate',
                      onPressed: _isLoading ? null : _generate,
                    ),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: AppTokens.s20),
              _ClozeCard(
                result: _result!,
                selectedAnswers: _selectedAnswers,
                answerCorrectness: _answerCorrectness,
                onSelect: _selectAnswer,
              ),
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
                  child: _ClozeHistoryCard(
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

class _ClozeCard extends StatelessWidget {
  const _ClozeCard({
    required this.result,
    required this.selectedAnswers,
    required this.answerCorrectness,
    required this.onSelect,
  });

  final Map<String, dynamic> result;
  final Map<int, String?> selectedAnswers;
  final Map<int, bool> answerCorrectness;
  final void Function(int blankIndex, String selected, String correct) onSelect;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passage = result['passage'] as String? ?? '';
    final blanks = (result['blanks'] as List<dynamic>?) ?? [];

    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cloze Test',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(passage, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppTokens.s16),
          ...blanks.asMap().entries.map((entry) {
            final index = entry.key;
            final blank = entry.value as Map<String, dynamic>;
            final correct = blank['answer'] as String? ?? '';
            final options =
                (blank['options'] as List<dynamic>?)?.cast<String>() ?? [];
            final selected = selectedAnswers[index];
            final isCorrect = answerCorrectness[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blank ${index + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ...options.asMap().entries.map((optEntry) {
                  final optIndex = optEntry.key;
                  final option = optEntry.value;
                  final letter = optIndex < _letters.length
                      ? _letters[optIndex]
                      : '${optIndex + 1}';

                  ChoiceState choiceState;
                  if (selected == null) {
                    choiceState = ChoiceState.idle;
                  } else if (option == selected) {
                    choiceState = isCorrect == true
                        ? ChoiceState.correct
                        : ChoiceState.wrong;
                  } else if (option == correct) {
                    choiceState = ChoiceState.correct;
                  } else {
                    choiceState = ChoiceState.idle;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.s8),
                    child: WordChoiceButton(
                      letter: letter,
                      text: option,
                      state: choiceState,
                      onTap: selected == null
                          ? () => onSelect(index, option, correct)
                          : null,
                    ),
                  );
                }),
                if (isCorrect != null) ...[
                  AppPill(
                    label: isCorrect
                        ? 'Correct!'
                        : 'Wrong! Answer: $correct',
                    variant:
                        isCorrect ? PillVariant.success : PillVariant.xp,
                  ),
                  const SizedBox(height: AppTokens.s12),
                ],
                const SizedBox(height: AppTokens.s4),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ClozeHistoryCard extends StatelessWidget {
  const _ClozeHistoryCard({required this.entry, required this.onDelete});

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              entry.response['passage'] as String? ?? '',
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
