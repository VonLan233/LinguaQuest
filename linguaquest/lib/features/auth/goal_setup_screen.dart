import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  String _target = 'Daily English';
  String _level = 'Elementary';
  int _dailyGoal = 10;

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
    return Scaffold(
      appBar: AppBar(title: const Text('Goal setup')),
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
                    label: '$_dailyGoal/day',
                    icon: Icons.today_outlined,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: _ChoiceSection(
                title: 'Target',
                values: targets,
                selected: _target,
                onSelected: (value) => setState(() => _target = value),
              ),
            ),
            const SizedBox(height: 20),
            QuestCard(
              child: _ChoiceSection(
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
                    'Daily goal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      for (final goal in goals)
                        ButtonSegment(value: goal, label: Text('$goal')),
                    ],
                    selected: {_dailyGoal},
                    onSelectionChanged: (values) =>
                        setState(() => _dailyGoal = values.first),
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
        );
    if (!mounted) return;
    if (!succeeded) return;
    context.go('/home');
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(value),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
                selectedColor: AppTheme.mint,
              ),
          ],
        ),
      ],
    );
  }
}
