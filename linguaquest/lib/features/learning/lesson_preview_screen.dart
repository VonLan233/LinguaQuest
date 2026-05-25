import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../data/models/lesson.dart';

class LessonPreviewScreen extends ConsumerWidget {
  const LessonPreviewScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = _findLesson(ref);
    if (lesson == null) {
      return const Scaffold(body: Center(child: Text('Lesson not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(lesson.section, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              lesson.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${lesson.xpReward} XP · ${lesson.estimatedMinutes} minutes · ${lesson.questions.length} questions',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Words in this lesson',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final word in lesson.words)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(word.imageCue)),
                title: Text(word.word),
                subtitle: Text('${word.meaning} · ${word.exampleSentence}'),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/lesson/$lessonId/quiz'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Lesson? _findLesson(WidgetRef ref) {
    for (final lesson in ref.watch(appControllerProvider).lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }
}
