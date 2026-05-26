import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
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
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/learn'),
        title: Text(lesson.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GradientHeroCard(
              title: lesson.title,
              subtitle: lesson.description,
              icon: Icons.auto_stories_outlined,
              badge: '${lesson.section} · ${lesson.estimatedMinutes} min',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                ),
                onPressed: () => context.push('/lesson/$lessonId/quiz'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start quiz'),
              ),
            ),
            const SizedBox(height: 18),
            QuestCard(
              child: Row(
                children: [
                  const ImageCueBadge(cue: '⚡', size: 58),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward pack',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lesson.xpReward} XP · ${lesson.questions.length} questions · instant explanations',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Image cards in this lesson',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final word in lesson.words)
              QuestCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    ImageCueBadge(cue: word.imageCue, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  word.word,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              PillLabel(
                                label: word.difficulty,
                                color: AppTheme.coral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(word.phonetic),
                          const SizedBox(height: 4),
                          Text('${word.meaning} · ${word.exampleSentence}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/lesson/$lessonId/quiz'),
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
