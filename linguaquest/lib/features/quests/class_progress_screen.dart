import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/class_group.dart';
import '../../data/models/lesson.dart';

class ClassProgressScreen extends ConsumerWidget {
  const ClassProgressScreen({this.classId, super.key});

  final String? classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(classProgressProvider(classId ?? ''));
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/class-mode'),
        title: const Text('班级进度'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(classProgressProvider(classId ?? '')),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              progress.when(
                data: (summary) => _ClassProgressBody(summary: summary),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(
                  '还没有可查看的班级进度。请先加入班级。',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassProgressBody extends ConsumerWidget {
  const _ClassProgressBody({required this.summary});

  final ClassProgressSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: summary.classGroup.name,
          subtitle:
              '${summary.classGroup.code} · ${summary.memberCount} 名成员 · 教师 ${summary.classGroup.teacherName}',
        ),
        const SizedBox(height: 14),
        _ClassSignals(summary: summary),
        const SizedBox(height: 22),
        const SectionHeader(title: '成员排行', subtitle: '按服务器积分和有效学习记录排序。'),
        const SizedBox(height: 12),
        if (summary.members.isEmpty)
          _EmptyLine(text: '班级还没有成员学习记录。')
        else
          for (final member in summary.members.take(8))
            _MemberRow(member: member),
        const SizedBox(height: 22),
        const SectionHeader(title: '练习进度', subtitle: '按班级最近完成的课程和训练统计。'),
        const SizedBox(height: 12),
        if (summary.lessons.isEmpty)
          _EmptyLine(text: '班级还没有完成课程或训练。')
        else
          for (final lesson in summary.lessons)
            _LessonRow(
              progress: lesson,
              title: _lessonTitle(state.lessons, lesson.lessonId),
            ),
        const SizedBox(height: 22),
        const SectionHeader(title: '班级弱项词', subtitle: '根据复习错误记录聚合。'),
        const SizedBox(height: 12),
        if (summary.weakWords.isEmpty)
          _EmptyLine(text: '暂时没有聚合到弱项词。')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final weak in summary.weakWords)
                PillLabel(
                  label:
                      '${state.targetWordById(weak.wordId)?.word ?? weak.wordId} · ${weak.mistakeCount}',
                  icon: Icons.warning_amber_outlined,
                  color: AppTheme.coral,
                ),
            ],
          ),
      ],
    );
  }
}

class _ClassSignals extends StatelessWidget {
  const _ClassSignals({required this.summary});

  final ClassProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Signal(
            label: '成员',
            value: '${summary.memberCount}',
            icon: Icons.groups_outlined,
            color: AppTheme.cyan,
          ),
        ),
        const _SignalDivider(),
        Expanded(
          child: _Signal(
            label: '答题',
            value: '${summary.totalQuestions}',
            icon: Icons.fact_check_outlined,
            color: AppTheme.mango,
          ),
        ),
        const _SignalDivider(),
        Expanded(
          child: _Signal(
            label: '正确率',
            value: '${(summary.accuracy * 100).round()}%',
            icon: Icons.insights_outlined,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.titleMedium),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignalDivider extends StatelessWidget {
  const _SignalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: VerticalDivider(
        width: 16,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final ClassMemberProgress member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconCueBadge(icon: Icons.person_outline, color: AppTheme.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${member.sessions} 次学习 · 正确率 ${(member.accuracy * 100).round()}%',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PillLabel(label: '${member.score} XP', color: AppTheme.mango),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.progress, required this.title});

  final ClassLessonProgress progress;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${progress.sessions} 次练习 · ${progress.correctAnswers}/${progress.totalQuestions} 题',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PillLabel(
            label: '${(progress.accuracy * 100).round()}%',
            color: AppTheme.cyan,
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

String _lessonTitle(List<Lesson> lessons, String id) {
  for (final lesson in lessons) {
    if (lesson.id == id) return lesson.title;
  }
  return id;
}
