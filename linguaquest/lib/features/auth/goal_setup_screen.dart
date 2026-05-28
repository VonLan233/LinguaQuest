import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/quest_card.dart';
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
        : _dailyWordsForDeadline(state.lessons, state.completedLessonIds);
    return Scaffold(
      appBar: AppBar(title: const Text('Goal Setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GradientHeroCard(
              title: 'Choose your learning plan',
              subtitle:
                  'We turn your target into daily lessons, reviews, and quests.',
              icon: Icons.track_changes_rounded,
              badge: 'Step 2 of 2',
              action: Row(
                children: [
                  PillLabel(
                    label: _target,
                    icon: Icons.flag_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  PillLabel(
                    label: '${plannedDailyWords ?? _dailyGoal}/day',
                    icon: Icons.today_outlined,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: _ChoiceSection<String>(
                title: 'Target',
                values: targets,
                selected: _target,
                onSelected: (value) => setState(() => _target = value),
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: _ChoiceSection<String>(
                title: 'Level',
                values: levels,
                selected: _level,
                onSelected: (value) => setState(() => _level = value),
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _ChoiceGrid<int>(
                    values: goals,
                    selected: _dailyGoal,
                    labelFor: (goal) => '$goal words',
                    onSelected: (goal) => setState(() => _dailyGoal = goal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan by Deadline',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _deadline == null
                        ? 'Choose a target date to calculate words per day.'
                        : '${formatShortDate(_deadline!)} · ${plannedDailyWords ?? _dailyGoal} words/day',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDeadline,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            _deadline == null ? 'Choose Date' : 'Change Date',
                          ),
                        ),
                      ),
                      if (_deadline != null) ...[
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          tooltip: 'Clear date plan',
                          onPressed: () => setState(() => _deadline = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Enter LinguaQuest'),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
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
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(deadline.year, deadline.month, deadline.day);
    final days = targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
    if (remainingWords == 0) return 1;
    return ((remainingWords + days - 1) ~/ days).clamp(1, 999).toInt();
  }
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
        _ChoiceGrid<T>(
          values: values,
          selected: selected,
          labelFor: labelFor ?? (value) => value.toString(),
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _ChoiceGrid<T> extends StatelessWidget {
  const _ChoiceGrid({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 3 : 2;
        const spacing = 10.0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          mainAxisExtent: 58,
          padding: EdgeInsets.zero,
          children: [
            for (final value in values)
              _StableChoiceButton(
                key: ValueKey('choice-${labelFor(value)}'),
                label: labelFor(value),
                selected: value == selected,
                onTap: () => onSelected(value),
              ),
          ],
        );
      },
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
        : theme.colorScheme.surfaceContainerHigh;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final textColor = selected
        ? (isDark ? theme.colorScheme.onPrimaryContainer : AppTheme.deepTeal)
        : theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
