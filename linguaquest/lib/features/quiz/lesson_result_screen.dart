import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
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
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Lesson complete',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$accuracy%',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${resolved.correctAnswers}/${resolved.totalQuestions} correct · ${resolved.xpEarned} XP earned',
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: resolved.accuracy),
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
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.verified_outlined),
                title: Text('Perfect run'),
                subtitle: Text('No mistakes were added to review.'),
              )
            else
              for (final mistake in resolved.mistakes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(mistake.word.imageCue)),
                  title: Text(mistake.word.word),
                  subtitle: Text(mistake.explanation),
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
