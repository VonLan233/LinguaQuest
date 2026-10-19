import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/generated/app_localizations.dart';

class AiSentenceGenScreen extends ConsumerStatefulWidget {
  const AiSentenceGenScreen({super.key});

  @override
  ConsumerState<AiSentenceGenScreen> createState() =>
      _AiSentenceGenScreenState();
}

class _AiSentenceGenScreenState extends ConsumerState<AiSentenceGenScreen> {
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

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = _controller.text.trim();
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });
    final result = await ref
        .read(appControllerProvider.notifier)
        .askAi(
          featureType: 'sentence_gen',
          prompt: AppLocalizations.of(context).aiUiSentencePrompt(input),
          targetWord: input,
        );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isEmpty) {
        _errorMessage =
            ref.read(appControllerProvider).errorMessage ??
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
        title: Text(AppLocalizations.of(context).aiUiSentenceGeneration),
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
                    AppLocalizations.of(context).aiUiEnterAWordOrASentence,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: _controller,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      ).aiUiAWordToBuildSentencesForOrASentenceToRewrite,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppLocalizations.of(
                            context,
                          ).aiUiPleaseEnterAWordOrSentence
                        : null,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading
                          ? AppLocalizations.of(context).aiUiGenerating
                          : AppLocalizations.of(context).aiUiGenerate,
                      onPressed: _isLoading ? null : _generate,
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
                  AppLocalizations.of(
                    context,
                  ).aiUiEnterAWordToGenerateExampleSentencesOrASentenceToGetRewriteSuggestions,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTokens.s20),
              AiErrorCard(message: _errorMessage!, onRetry: _generate),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppTokens.s20),
              _SentenceResult(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentenceResult extends StatelessWidget {
  const _SentenceResult({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentences = (result['sentences'] as List<dynamic>?) ?? const [];
    final rewrites = (result['rewrites'] as List<dynamic>?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sentences.isNotEmpty) ...[
          Text(
            AppLocalizations.of(context).aiUiExampleSentences,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final raw in sentences)
            if (raw is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: AppCard(
                  padding: const EdgeInsets.all(AppTokens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${raw['sentence'] ?? ''}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        '${raw['translation'] ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
        if (rewrites.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s12),
          Text(
            AppLocalizations.of(context).aiUiRewrites,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final raw in rewrites)
            if (raw is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: AppCard(
                  padding: const EdgeInsets.all(AppTokens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${raw['original'] ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        '${raw['rewritten'] ?? ''}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      if ('${raw['note'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          '${raw['note']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
