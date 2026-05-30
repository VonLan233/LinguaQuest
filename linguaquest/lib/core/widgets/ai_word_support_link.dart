import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'learning_badges.dart';

class AiWordSupportLink extends StatelessWidget {
  const AiWordSupportLink({required this.word, super.key});

  final String word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/ai-learning'),
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
                      '围绕 $word 提问用法、语法、近义词区别和例句拆解。',
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
}
