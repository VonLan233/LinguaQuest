import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../data/models/lesson_result.dart';

class LessonResultScreen extends ConsumerWidget {
  const LessonResultScreen({this.result, super.key});

  final LessonResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = result ?? ref.watch(appControllerProvider).lastResult;
    if (resolved == null) {
      return const Scaffold(body: Center(child: Text('No lesson result yet')));
    }

    final accuracy = (resolved.accuracy * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GradientHeroCard(
              title: accuracy >= 80 ? 'Brilliant run!' : 'Lesson complete',
              subtitle:
                  '${resolved.correctAnswers}/${resolved.totalQuestions} correct · ${resolved.xpEarned} XP earned · mistakes moved into review.',
              icon: Icons.workspace_premium_outlined,
              badge: resolved.lessonTitle,
            ),
            const SizedBox(height: 12),
            QuestCard(
              child: Column(
                children: [
                  Text(
                    '$accuracy%',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Accuracy'),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: resolved.accuracy,
                      minHeight: 12,
                      backgroundColor: AppTheme.mint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PillLabel(
                        label: '+${resolved.xpEarned} XP',
                        icon: Icons.bolt,
                        color: AppTheme.mango,
                      ),
                      const SizedBox(width: 8),
                      PillLabel(
                        label: '${resolved.mistakes.length} mistakes',
                        icon: Icons.replay_rounded,
                        color: AppTheme.coral,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mistakes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (resolved.mistakes.isEmpty)
              const QuestCard(
                child: Row(
                  children: [
                    ImageCueBadge(cue: '🏆', size: 58),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Perfect run'),
                          Text('No mistakes were added to review.'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final mistake in resolved.mistakes)
                QuestCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ImageCueBadge(cue: mistake.word.imageCue, size: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mistake.word.word,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(mistake.explanation),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/review'),
              icon: const Icon(Icons.replay),
              label: const Text('Go to review center'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/learn'),
              icon: const Icon(Icons.route_outlined),
              label: const Text('Back to learning path'),
            ),
          ],
        ),
      ),
    );
  }
}
