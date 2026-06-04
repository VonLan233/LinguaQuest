import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/study_plan.dart';

class StudyPlanSettingsScreen extends ConsumerStatefulWidget {
  const StudyPlanSettingsScreen({super.key});

  @override
  ConsumerState<StudyPlanSettingsScreen> createState() =>
      _StudyPlanSettingsScreenState();
}

class _StudyPlanSettingsScreenState
    extends ConsumerState<StudyPlanSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dailyNewController = TextEditingController();
  final _dailyReviewController = TextEditingController();

  late final ProviderSubscription<AppState> _stateSubscription;
  var _initialized = false;
  var _wordBookId = 'daily-english';
  var _targetFinishDate = DateTime.now().add(const Duration(days: 30));
  var _reminderTime = const TimeOfDay(hour: 20, minute: 0);

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
    _dailyNewController.dispose();
    _dailyReviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    if (user == null) {
      return const Scaffold(
        appBar: _StudyPlanAppBar(),
        body: Center(child: Text('请先登录后再设置学习计划。')),
      );
    }

    final lessons = learningLessonsForTarget(state.lessons, _wordBookId);
    final totalWords = lessons.fold<int>(
      0,
      (total, lesson) => total + lesson.words.length,
    );
    final completedWords = lessons
        .where((lesson) => state.completedLessonIds.contains(lesson.id))
        .fold<int>(0, (total, lesson) => total + lesson.words.length);
    final progress = totalWords == 0
        ? 0.0
        : (completedWords / totalWords).clamp(0.0, 1.0);
    final book = studyBookInfoForId(_wordBookId);
    final plan = state.studyPlan;

    return Scaffold(
      appBar: const _StudyPlanAppBar(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: state.isLoading ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存学习计划'),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 104),
            children: [
              SectionHeader(
                title: '学习计划设置',
                subtitle: '管理当前词书、每日任务、复习节奏和提醒时间。',
                trailing: QuestIconButton(
                  tooltip: '查看完整词汇表',
                  onPressed: () => context.push('/wordbook'),
                  icon: Icons.style_outlined,
                  color: AppTheme.cyan,
                ),
              ),
              const SizedBox(height: 16),
              _PlanHeroCard(
                book: book,
                totalWords: totalWords,
                completedWords: completedWords,
                progress: progress,
                status: plan?.status ?? 'active',
                daysLeft: (plan ?? _fallbackPlan(user.uid)).daysLeft(
                  DateTime.now(),
                ),
              ),
              const SizedBox(height: 24),
              _StudyBookSelector(
                selectedId: _wordBookId,
                onSelected: (value) => setState(() => _wordBookId = value),
              ),
              const SizedBox(height: 24),
              _NumberField(
                controller: _dailyNewController,
                label: '每日新学词数',
                helperText: '建议 5-30 词，最多 200 词。',
                icon: Icons.add_task_outlined,
                min: 1,
                max: 200,
              ),
              const SizedBox(height: 16),
              _NumberField(
                controller: _dailyReviewController,
                label: '每日复习上限',
                helperText: '复习队列超过上限时会保留到后续日期。',
                icon: Icons.replay_outlined,
                min: 0,
                max: 500,
              ),
              const SizedBox(height: 22),
              _PlanDateTimeSection(
                targetFinishDate: _targetFinishDate,
                reminderTimeLabel: _reminderTimeLabel,
                onPickDate: _pickTargetFinishDate,
                onPickTime: _pickReminderTime,
              ),
              const SizedBox(height: 24),
              _PlanActions(
                isPaused: plan?.isPaused ?? false,
                isLoading: state.isLoading,
                onOpenWords: () => context.push('/wordbook'),
                onTogglePause: _togglePause,
                onReset: _confirmReset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeFromState(AppState state, {required bool notify}) {
    if (_initialized) return;
    final user = state.user;
    if (user == null) return;
    final plan = state.studyPlan ?? _fallbackPlan(user.uid);

    void updateFields() {
      _wordBookId = plan.wordBookId;
      _dailyNewController.text = plan.dailyNewTarget.toString();
      _dailyReviewController.text = plan.dailyReviewLimit.toString();
      _targetFinishDate = plan.targetFinishDate;
      final parts = plan.reminderTime.split(':');
      _reminderTime = TimeOfDay(
        hour: int.tryParse(parts.first) ?? 20,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      );
      _initialized = true;
    }

    if (notify && mounted) {
      setState(updateFields);
    } else {
      updateFields();
    }
  }

  StudyPlan _fallbackPlan(String uid) {
    final state = ref.read(appControllerProvider);
    return StudyPlan.defaultsFor(
      uid: uid,
      targetExam: state.user?.targetExam ?? 'Daily English',
      dailyGoal: state.user?.dailyGoal ?? 10,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = ref.read(appControllerProvider);
    final user = state.user;
    if (user == null) return;
    final today = _dateOnly(DateTime.now());
    final finishDate = _dateOnly(_targetFinishDate);
    if (finishDate.isBefore(today)) {
      _showMessage('目标完成日期不能早于今天。');
      return;
    }

    final basePlan = state.studyPlan ?? _fallbackPlan(user.uid);
    final plan = basePlan.copyWith(
      uid: user.uid,
      wordBookId: _wordBookId,
      dailyNewTarget: int.parse(_dailyNewController.text.trim()),
      dailyReviewLimit: int.parse(_dailyReviewController.text.trim()),
      targetFinishDate: finishDate,
      reminderTime: _reminderTimeLabel,
      updatedAt: DateTime.now(),
    );
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .updateStudyPlan(plan);
    if (!mounted) return;
    _showMessage(succeeded ? '学习计划已保存。' : state.errorMessage ?? '暂时无法保存计划。');
  }

  Future<void> _togglePause() async {
    final wasPaused =
        ref.read(appControllerProvider).studyPlan?.isPaused ?? false;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .toggleStudyPlanPaused();
    if (!mounted) return;
    _showMessage(
      succeeded
          ? wasPaused
                ? '学习计划已恢复。'
                : '学习计划已暂停，今日提醒和任务入口会暂时关闭。'
          : '暂时无法更新计划状态。',
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置学习计划？'),
        content: const Text(
          '重置后会清空当前词书的学习路径进度，并把生词本掌握度、正确/错误次数和复习时间重置；复习队列会重新生成。这个操作会影响学习进度和复习安排。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .resetStudyPlan();
    if (!mounted) return;
    _showMessage(succeeded ? '学习计划已重置。' : '暂时无法重置计划。');
  }

  Future<void> _pickTargetFinishDate() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetFinishDate.isBefore(today)
          ? today
          : _targetFinishDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() => _targetFinishDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _reminderTime = picked);
  }

  String get _reminderTimeLabel {
    final hour = _reminderTime.hour.toString().padLeft(2, '0');
    final minute = _reminderTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _StudyPlanAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StudyPlanAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const FallbackBackButton(fallbackLocation: '/settings'),
      title: const Text('学习计划'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.book,
    required this.totalWords,
    required this.completedWords,
    required this.progress,
    required this.status,
    required this.daysLeft,
  });

  final StudyBookInfo book;
  final int totalWords;
  final int completedWords;
  final double progress;
  final String status;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.teal.withValues(alpha: 0.18),
                child: Text(book.cover, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      book.description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 11,
              backgroundColor: AppTheme.progressTrack(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PillLabel(
                label: '已学 $completedWords/$totalWords 词',
                icon: Icons.school_outlined,
                color: AppTheme.teal,
              ),
              PillLabel(
                label: '剩余 $daysLeft 天',
                icon: Icons.event_outlined,
                color: AppTheme.mango,
              ),
              PillLabel(
                label: status == 'paused' ? '已暂停' : '进行中',
                icon: status == 'paused'
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: status == 'paused' ? AppTheme.coral : AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyBookSelector extends StatelessWidget {
  const _StudyBookSelector({
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('切换词书', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final book in studyBooks)
              _StudyBookPill(
                book: book,
                selected: selectedId == book.id,
                onTap: () => onSelected(book.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _StudyBookPill extends StatelessWidget {
  const _StudyBookPill({
    required this.book,
    required this.selected,
    required this.onTap,
  });

  final StudyBookInfo book;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(book.cover),
              const SizedBox(width: 6),
              Text(
                book.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helperText,
    required this.icon,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String helperText;
  final IconData icon;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        helperText: helperText,
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null) return '请输入数字';
        if (parsed < min || parsed > max) return '范围必须是 $min-$max';
        return null;
      },
    );
  }
}

class _PlanDateTimeSection extends StatelessWidget {
  const _PlanDateTimeSection({
    required this.targetFinishDate,
    required this.reminderTimeLabel,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime targetFinishDate;
  final String reminderTimeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlanActionRow(
          icon: Icons.event_outlined,
          title: '考试/目标完成日期',
          subtitle: formatShortDate(targetFinishDate),
          onTap: onPickDate,
        ),
        const Divider(height: 18),
        _PlanActionRow(
          icon: Icons.schedule_outlined,
          title: '学习提醒时间',
          subtitle: reminderTimeLabel,
          onTap: onPickTime,
        ),
      ],
    );
  }
}

class _PlanActions extends StatelessWidget {
  const _PlanActions({
    required this.isPaused,
    required this.isLoading,
    required this.onOpenWords,
    required this.onTogglePause,
    required this.onReset,
  });

  final bool isPaused;
  final bool isLoading;
  final VoidCallback onOpenWords;
  final VoidCallback onTogglePause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenWords,
          icon: const Icon(Icons.style_outlined),
          label: const Text('查看完整词汇表'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onTogglePause,
          icon: Icon(
            isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
          ),
          label: Text(isPaused ? '恢复计划' : '暂停计划'),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: isLoading ? null : onReset,
          icon: const Icon(Icons.restart_alt_outlined),
          label: const Text('重置计划'),
        ),
      ],
    );
  }
}

class _PlanActionRow extends StatelessWidget {
  const _PlanActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              IconCueBadge(icon: icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
