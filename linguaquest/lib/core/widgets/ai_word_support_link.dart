import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'learning_badges.dart';

class AiWordSupportLink extends StatelessWidget {
  const AiWordSupportLink({
    required this.word,
    this.exampleSentence = '',
    this.exampleTranslation = '',
    super.key,
  });

  final String word;
  final String exampleSentence;
  final String exampleTranslation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openAiLearning(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconCueBadge(
                icon: AppIcons.autoAwesome,
                color: AppTheme.cyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiLearningTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _description(l10n),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiLearning(BuildContext context) {
    context.go(_aiLearningLocation());
  }

  String _description(AppLocalizations l10n) {
    final example = exampleSentence.trim();
    if (example.isEmpty) {
      return l10n.aiWordSupportDesc(word);
    }
    return l10n.aiWordSupportWithExampleDesc(word);
  }

  String _aiLearningLocation() {
    return Uri(
      path: '/ai-learning',
      queryParameters: {
        'word': word,
        if (exampleSentence.trim().isNotEmpty)
          'example': exampleSentence.trim(),
        if (exampleTranslation.trim().isNotEmpty)
          'translation': exampleTranslation.trim(),
      },
    ).toString();
  }
}
