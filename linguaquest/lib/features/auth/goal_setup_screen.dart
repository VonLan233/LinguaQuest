import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';
import '../../data/models/study_plan.dart';
import '../../l10n/generated/app_localizations.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  String _target = 'Daily English';
  String _level = 'Intermediate';
  int _dailyGoal = 10;
  DateTime? _deadline;
  var _initializedFromState = false;
  late final ProviderSubscription<AppState> _stateSubscription;

  static const targets = [
    'IELTS',
    'TOEFL',
    'GRE',
    'Beginner',
    'Daily English',
  ];
  static const goals = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _stateSubscription = ref.listenManual<AppState>(appControllerProvider, (
      previous,
      next,
    ) {
      _initializeFromState(next, notify: previous != null);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _stateSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final selectedBook = _bookForTarget(state.wordBooks, _target);
    final selectedLessons = learningLessonsForTarget(state.lessons, _target);
    final totalWords =
        selectedBook?.totalWords ??
        selectedLessons.fold<int>(
          0,
          (total, lesson) => total + lesson.words.length,
        );
    final completedWords = selectedBook?.id == state.currentWordBookId
        ? selectedLessons
              .where((lesson) => state.completedLessonIds.contains(lesson.id))
              .fold<int>(0, (total, lesson) => total + lesson.words.length)
        : 0;
    final plannedDailyWords = _deadline == null
        ? null
        : _dailyWordsForDeadline(totalWords - completedWords);
    final dailyWords = plannedDailyWords ?? _dailyGoal;
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.goalSetupTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            SectionHeader(
                title: l10n.goalSetupSelectPlan,
                subtitle: l10n.goalSetupSelectPlanSubtitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(
                  label: l10n.authStep2of2,
                  icon: Icons.track_changes_rounded,
                  color: AppTheme.cyan,
                ),
                PillLabel(
                  label: displayTarget(_target, l10n: l10n),
                  icon: Icons.flag_outlined,
                ),
                PillLabel(
                  label: '$dailyWords${l10n.commonWords}/${l10n.commonDay}',
                  icon: Icons.today_outlined,
                  color: AppTheme.mango,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PlanSnapshotLine(
              target: displayTarget(_target, l10n: l10n),
              totalWords: totalWords,
              completedWords: completedWords,
              dailyWords: dailyWords,
              reviewLimit: dailyWords * 2,
              onOpenWordbook: () => context.push('/wordbook'),
              l10n: l10n,
            ),
            const SizedBox(height: 20),
            _ChoiceSection<String>(
              title: l10n.goalSetupTarget,
              values: targets,
              selected: _target,
              labelFor: (v) => displayTarget(v, l10n: l10n),
              onSelected: (value) => setState(() => _target = value),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.goalSetupDailyGoal,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _ChoiceList<int>(
                  values: goals,
                  selected: _dailyGoal,
                  labelFor: (goal) => '$goal ${l10n.commonWords}',
                  onSelected: (goal) => setState(() => _dailyGoal = goal),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.goalSetupDeadlinePlan,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _deadline == null
                      ? l10n.goalSetupDeadlineHint
                      : '${formatShortDate(_deadline!)} · ${plannedDailyWords ?? _dailyGoal} ${l10n.commonWords}/${l10n.commonDay}',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDeadline,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          _deadline == null
                              ? l10n.goalSetupPickDate
                              : l10n.goalSetupChangeDate,
                        ),
                      ),
                    ),
                    if (_deadline != null) ...[
                      const SizedBox(width: 10),
                      QuestIconButton(
                        tooltip: l10n.goalSetupClearDate,
                        onPressed: () => setState(() => _deadline = null),
                        icon: Icons.close_rounded,
                        color: AppTheme.coral,
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
              label: Text(l10n.goalSetupEnterApp),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeFromState(AppState state, {required bool notify}) {
    if (_initializedFromState) return;
    final user = state.user;
    if (user == null) return;
    void updateFields() {
      _target = state.studyPlan == null
          ? user.targetExam
          : targetForStudyBookId(state.studyPlan!.wordBookId);
      _level = user.level;
      _dailyGoal = state.studyPlan?.dailyNewTarget ?? user.dailyGoal;
      _deadline = state.studyPlan?.targetFinishDate;
      _initializedFromState = true;
    }

    if (notify && mounted) {
      setState(updateFields);
    } else {
      updateFields();
    }
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

  int _dailyWordsForDeadline(int remainingWords) {
    final now = DateTime.now();
    final deadline = _deadline ?? now;
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final days = targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
    if (remainingWords == 0) return 1;
    return ((remainingWords + days - 1) ~/ days).clamp(1, 999).toInt();
  }

  WordBook? _bookForTarget(List<WordBook> books, String target) {
    final normalized = target.toLowerCase();
    for (final book in books) {
      final examType = book.examType.toLowerCase();
      final title = book.title.toLowerCase();
      if (examType == normalized || title.contains(normalized)) return book;
      if (normalized == '考研' && book.id == 'kaoyan') return book;
      if (normalized == 'daily english' && book.id == 'beginner') return book;
      if (normalized == 'business english' && book.id == 'beginner') {
        return book;
      }
    }
    return null;
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

class _PlanSnapshotLine extends StatelessWidget {
  const _PlanSnapshotLine({
    required this.target,
    required this.totalWords,
    required this.completedWords,
    required this.dailyWords,
    required this.reviewLimit,
    required this.onOpenWordbook,
    required this.l10n,
  });

  final String target;
  final int totalWords;
  final int completedWords;
  final int dailyWords;
  final int reviewLimit;
  final VoidCallback onOpenWordbook;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalWords == 0
        ? 0.0
        : (completedWords / totalWords).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconCueBadge(
              icon: Icons.menu_book_outlined,
              color: AppTheme.cyan,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.goalSetupCurrentBook,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    '$target · ${l10n.goalSetupLearned} $completedWords/$totalWords ${l10n.commonWords}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppTheme.progressTrack(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PillLabel(
              label: l10n.goalSetupNewWordsCount(dailyWords),
              icon: Icons.add_task_rounded,
              color: AppTheme.teal,
            ),
            PillLabel(
              label: l10n.goalSetupReviewLimitCount(reviewLimit),
              icon: Icons.replay_rounded,
              color: AppTheme.mango,
            ),
            TextButton.icon(
              onPressed: onOpenWordbook,
              icon: const Icon(Icons.style_outlined),
              label: Text(l10n.goalSetupViewWordbook),
            ),
          ],
        ),
      ],
    );
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
