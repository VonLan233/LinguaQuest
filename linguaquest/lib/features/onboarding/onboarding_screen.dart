import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      const _OnboardingCard(
        cue: '🖼',
        icon: Icons.image_search_outlined,
        title: 'Image word cards',
        body: 'Words carry meaning, examples, mastery, and visual cues.',
      ),
      const _OnboardingCard(
        cue: '🛤',
        icon: Icons.route_outlined,
        title: 'A clear path',
        body:
            'Short lessons decide what to learn next, so daily study stays simple.',
      ),
      const _OnboardingCard(
        cue: '🔁',
        icon: Icons.replay_outlined,
        title: 'Review at the right time',
        body: 'Weak words return sooner; mastered words wait longer.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            GradientHeroCard(
              title: 'LinguaQuest',
              subtitle:
                  'Build an English habit with bite-sized lessons, visual memory cards, and smart review.',
              icon: Icons.language_rounded,
              badge: '词境星球 · Learn in context',
              action: Row(
                children: [
                  const PillLabel(
                    label: 'XP',
                    icon: Icons.bolt,
                    color: AppTheme.mango,
                  ),
                  const SizedBox(width: 8),
                  PillLabel(
                    label: 'Streak',
                    icon: Icons.local_fire_department,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Pick up where modern language apps work best',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final card in cards) ...[card, const SizedBox(height: 12)],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create account'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.cue,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String cue;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuestCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ImageCueBadge(cue: cue, size: 68),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
