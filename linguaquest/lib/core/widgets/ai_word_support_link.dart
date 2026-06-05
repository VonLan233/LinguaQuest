import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                icon: Icons.auto_awesome_outlined,
                color: AppTheme.cyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI 学习', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      _description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiLearning(BuildContext context) {
    final location = _aiLearningLocation();
    if (location == '/ai-learning') {
      context.push('/ai-learning');
      return;
    }
    context.push(location);
  }

  String get _description {
    final example = exampleSentence.trim();
    if (example.isEmpty) {
      return '围绕 $word 提问用法、语法、近义词区别和例句拆解。';
    }
    return '携带 $word 和当前例句，提问用法、语法、近义词区别和例句拆解。';
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
