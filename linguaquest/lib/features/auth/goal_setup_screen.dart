import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  String _target = 'Daily English';
  String _level = 'Elementary';
  int _dailyGoal = 10;
  DateTime? _deadline;

  static const targets = [
    'CET-4',
    'CET-6',
    'IELTS',
    'TOEFL',
    'MUET',
    'Daily English',
    'Business English',
  ];
  static const levels = ['Beginner', 'Elementary', 'Intermediate', 'Advanced'];
  static const goals = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final plannedDailyWords = _deadline == null
        ? null
        : _dailyWordsForDeadline(state.formalLessons, state.completedLessonIds);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('目标设置'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            SectionHeader(title: '选择学习计划', subtitle: '系统会把目标拆成每日新学、到期复习和积分任务。'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(
                  label: '第 2 步 / 共 2 步',
                  icon: Icons.track_changes_rounded,
                  color: AppTheme.cyan,
                ),
                PillLabel(
                  label: displayTarget(_target),
                  icon: Icons.flag_outlined,
                ),
                PillLabel(
                  label: '${plannedDailyWords ?? _dailyGoal}/天',
                  icon: Icons.today_outlined,
                  color: AppTheme.mango,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ChoiceSection<String>(
              title: '目标',
              values: targets,
              selected: _target,
              labelFor: displayTarget,
              onSelected: (value) => setState(() => _target = value),
            ),
            const SizedBox(height: 24),
            _ChoiceSection<String>(
              title: '水平',
              values: levels,
              selected: _level,
              labelFor: displayLevel,
              onSelected: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('每日目标', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _ChoiceList<int>(
                  values: goals,
                  selected: _dailyGoal,
                  labelFor: (goal) => '$goal 词',
                  onSelected: (goal) => setState(() => _dailyGoal = goal),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('按截止日期规划', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _deadline == null
                      ? '选择目标日期后，系统会自动计算每天需要学习的词数。'
                      : '${formatShortDate(_deadline!)} · 每天 ${plannedDailyWords ?? _dailyGoal} 词',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDeadline,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(_deadline == null ? '选择日期' : '更改日期'),
                      ),
                    ),
                    if (_deadline != null) ...[
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: '清除日期规划',
                        onPressed: () => setState(() => _deadline = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('进入 LinguaQuest'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .completeGoalSetup(
          targetExam: _target,
          level: _level,
          dailyGoal: _dailyGoal,
          deadline: _deadline,
        );
    if (!mounted) return;
    if (!succeeded) return;
    context.go('/home');
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = today.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: clampDeadlinePickerInitialDate(
        selected: _deadline,
        now: now,
      ),
      firstDate: today,
      lastDate: lastDate,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _deadline = picked);
  }

  int _dailyWordsForDeadline(
    List<Lesson> lessons,
    Set<String> completedLessonIds,
  ) {
    final remainingWords = lessons
        .where((lesson) => !completedLessonIds.contains(lesson.id))
        .fold(0, (total, lesson) => total + lesson.words.length);
    final now = DateTime.now();
    final deadline = _deadline ?? now;
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final days = targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
    if (remainingWords == 0) return 1;
    return ((remainingWords + days - 1) ~/ days).clamp(1, 999).toInt();
  }
}

DateTime clampDeadlinePickerInitialDate({
  required DateTime now,
  DateTime? selected,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final lastDate = today.add(const Duration(days: 365));
  if (selected == null) return today.add(const Duration(days: 30));

  final selectedDay = DateTime(selected.year, selected.month, selected.day);
  if (selectedDay.isBefore(today)) return today.add(const Duration(days: 30));
  if (selectedDay.isAfter(lastDate)) return lastDate;
  return selectedDay;
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
    this.labelFor,
  });

  final String title;
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T value)? labelFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _ChoiceList<T>(
          values: values,
          selected: selected,
          labelFor: labelFor ?? (value) => value.toString(),
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ChoiceList<T> extends StatelessWidget {
  const _ChoiceList({
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          _StableChoiceButton(
            key: ValueKey('choice-${values[index]}'),
            label: labelFor(values[index]),
            selected: values[index] == selected,
            onTap: () => onSelected(values[index]),
          ),
          if (index != values.length - 1)
            Divider(
              height: 4,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _StableChoiceButton extends StatelessWidget {
  const _StableChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppTheme.isDark(context);
    final background = selected
        ? AppTheme.selectedSurface(context)
        : Colors.transparent;
    final borderColor = selected
        ? theme.colorScheme.primary
        : Colors.transparent;
    final textColor = selected
        ? (isDark ? theme.colorScheme.onPrimaryContainer : AppTheme.deepTeal)
        : theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
