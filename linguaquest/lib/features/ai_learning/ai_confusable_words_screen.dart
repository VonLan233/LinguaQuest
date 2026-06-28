import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/generated/app_localizations.dart';

class AiConfusableWordsScreen extends ConsumerStatefulWidget {
  const AiConfusableWordsScreen({super.key});

  @override
  ConsumerState<AiConfusableWordsScreen> createState() =>
      _AiConfusableWordsScreenState();
}

class _AiConfusableWordsScreenState
    extends ConsumerState<AiConfusableWordsScreen> {
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

  Future<void> _analyze() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = _controller.text.trim();
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });
    final result = await ref.read(appControllerProvider.notifier).askAi(
          featureType: 'confusion',
          prompt: 'Distinguish words confusable with: $input',
          targetWord: input,
        );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isEmpty) {
        _errorMessage = ref.read(appControllerProvider).errorMessage ??
            AppLocalizations.of(context).aiErrorGeneric;
      } else {
        _result = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confusable Words'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s20, AppTokens.s20, AppTokens.s20, 88),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter a word to compare with its look-alikes',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: _controller,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 在 / 再, affect / effect...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a word'
                        : null,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading ? 'Analyzing...' : 'Analyze',
                      onPressed: _isLoading ? null : _analyze,
                    ),
                  ),
                ],
              ),
            ),
            if (_result == null && _errorMessage == null && !_isLoading) ...[
              const SizedBox(height: AppTokens.s20),
              AppCard(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Text(
                  'Enter a word to see commonly confused look-alikes and how to tell them apart.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTokens.s20),
              AiErrorCard(message: _errorMessage!, onRetry: _analyze),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppTokens.s20),
              _ConfusionResult(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfusionResult extends StatelessWidget {
  const _ConfusionResult({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairs = (result['pairs'] as List<dynamic>?) ?? const [];
    if (pairs.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Text('No confusable words found.',
            style: theme.textTheme.bodyMedium),
      );
    }
    return Column(
      children: [
        for (final raw in pairs)
          if (raw is Map)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s12),
              child: AppCard(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${raw['word'] ?? ''}  vs  ${raw['confusedWith'] ?? ''}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text('${raw['distinction'] ?? ''}',
                        style: theme.textTheme.bodyMedium),
                    if (raw['examples'] is List &&
                        (raw['examples'] as List).isNotEmpty) ...[
                      const SizedBox(height: AppTokens.s8),
                      for (final ex in (raw['examples'] as List))
                        Padding(
                          padding: const EdgeInsets.only(top: AppTokens.s4),
                          child: Text('• $ex',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
