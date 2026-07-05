import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/wordbook_progress.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/wordbook_cover_card.dart';
import '../../data/models/lesson.dart';
import '../../data/models/study_plan.dart';
import '../../data/models/user_word.dart';
import '../../l10n/generated/app_localizations.dart';

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

  late final ProviderSubscription<AppState> _stateSubscription;
  _PlanInitializationKey? _lastInitializedPlanKey;
  var _initialized = false;
  var _wordBookId = 'beginner';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    if (user == null) {
      return Scaffold(
        appBar: const _StudyPlanAppBar(),
        body: Center(child: Text(l10n.studyPlanLoginRequired)),
      );
    }

    final localeCode = Localizations.localeOf(context).languageCode;
    final selectedWordBook = _wordBookForId(state.wordBooks, _wordBookId);
    final lessons = learningLessonsForTarget(state.lessons, _wordBookId);
    final fallbackWords = lessons.expand((lesson) => lesson.words).toList();
    final selectedWordIds =
        selectedWordBook?.wordIds.toSet() ??
        fallbackWords.map((word) => word.id).toSet();
    final totalWords = selectedWordBook?.totalWords ?? fallbackWords.length;
    final completedWords = learnedWordCountForBook(
      userWords: state.userWords,
      wordBookId: _wordBookId,
      wordIds: selectedWordIds,
    );
    final progress = wordbookProgressValue(
      learnedWords: completedWords,
      totalWords: totalWords,
    );
    final book = selectedWordBook != null
        ? StudyBookInfo(
            id: selectedWordBook.id,
            name: selectedWordBook.nameFor(localeCode),
            cover: studyPlanCoverEmoji(selectedWordBook.language),
            description: selectedWordBook.description,
          )
        : studyBookInfoForId(_wordBookId);
    final plan = state.studyPlan;

    return Scaffold(
      appBar: const _StudyPlanAppBar(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPrimaryButton(
                label: l10n.studyPlanSave,
                icon: AppIcons.save,
                onPressed: state.isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 104),
            children: [
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
              SectionHeader(
                title: l10n.studyPlanSettings,
                subtitle: l10n.studyPlanSettingsDesc,
                trailing: QuestIconButton(
                  tooltip: l10n.studyPlanViewWords,
                  onPressed: () => context.push('/wordbook'),
                  icon: AppIcons.style,
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
                l10n: l10n,
              ),
              const SizedBox(height: 24),
              _CurrentLanguageTile(
                currentLanguage: state.currentLanguage,
                l10n: l10n,
                onTap: () => showLanguageWordbookPicker(context),
              ),
              const SizedBox(height: AppTokens.s12),
              _StudyBookSelector(
                books: state.wordBooks
                    .where((b) => b.language == state.currentLanguage)
                    .toList(),
                userWords: state.userWords,
                selectedId: _wordBookId,
                localeCode: localeCode,
                onSelected: (value) => _selectWordBook(value),
                l10n: l10n,
              ),
              const SizedBox(height: 40),
              _NumberField(
                controller: _dailyNewController,
                label: l10n.studyPlanDailyNew,
                helperText: l10n.studyPlanDailyNewHint,
                icon: AppIcons.addTask,
                min: 1,
                max: 200,
                l10n: l10n,
              ),
              const SizedBox(height: 22),
              _PlanDateTimeSection(
                reminderTimeLabel: _reminderTimeLabel,
                onPickTime: _pickReminderTime,
                l10n: l10n,
              ),
              const SizedBox(height: 24),
              _PlanActions(
                isPaused: plan?.isPaused ?? false,
                isLoading: state.isLoading,
                onOpenWords: () => context.push('/wordbook'),
                onTogglePause: _togglePause,
                onReset: _confirmReset,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeFromState(AppState state, {required bool notify}) {
    final user = state.user;
    if (user == null) return;
    final statePlan = state.studyPlan;
    final plan = statePlan ?? _fallbackPlan(user.uid);
    final planKey = statePlan == null
        ? _PlanInitializationKey.fallback(user.uid)
        : _PlanInitializationKey.fromPlan(statePlan);
    if (_initialized && _lastInitializedPlanKey == planKey) {
      return;
    }

    void updateFields() {
      _wordBookId = plan.wordBookId;
      _dailyNewController.text = plan.dailyNewTarget.toString();
      _reminderTime = parseStudyPlanReminderTime(plan.reminderTime);
      _initialized = true;
      _lastInitializedPlanKey = planKey;
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
    final dailyNew = int.parse(_dailyNewController.text.trim());
    final selectedWordBook = _wordBookForId(state.wordBooks, _wordBookId);
    final finishDate = studyPlanAutoFinishDate(
      totalWords: selectedWordBook?.totalWords ?? 0,
      dailyNewTarget: dailyNew,
      today: today,
    );
    final basePlan = state.studyPlan ?? _fallbackPlan(user.uid);

    final plan = basePlan.copyWith(
      uid: user.uid,
      wordBookId: _wordBookId,
      dailyNewTarget: dailyNew,
      dailyReviewLimit: state.dueWords.length.clamp(0, 200).toInt(),
      targetFinishDate: finishDate,
      reminderTime: _reminderTimeLabel,
      updatedAt: DateTime.now(),
    );
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .updateStudyPlan(plan);
    if (!mounted) return;
    final latestState = ref.read(appControllerProvider);
    _showMessage(
      succeeded
          ? AppLocalizations.of(context).studyPlanSaved
          : latestState.errorMessage ??
                AppLocalizations.of(context).studyPlanSaveFailed,
    );
  }

  Future<void> _selectWordBook(String value) async {
    setState(() => _wordBookId = value);
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .switchWordBook(value);
    if (!mounted || succeeded) return;
    final error = ref.read(appControllerProvider).errorMessage;
    _showMessage(error ?? AppLocalizations.of(context).pickerSwitchFailed);
  }

  Future<void> _togglePause() async {
    final l10n = AppLocalizations.of(context);
    final wasPaused =
        ref.read(appControllerProvider).studyPlan?.isPaused ?? false;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .toggleStudyPlanPaused();
    if (!mounted) return;
    _showMessage(
      succeeded
          ? wasPaused
                ? l10n.studyPlanResumed
                : l10n.studyPlanPaused
          : l10n.studyPlanPauseFailed,
    );
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.studyPlanResetConfirm),
        content: Text(l10n.studyPlanResetDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.studyPlanCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.studyPlanConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .resetStudyPlan();
    if (!mounted) return;
    _showMessage(
      succeeded ? l10n.studyPlanResetDone : l10n.studyPlanResetFailed,
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      initialEntryMode: studyPlanReminderTimePickerEntryMode,
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
    return _studyPlanDateOnly(value);
  }
}

const studyPlanReminderTimePickerEntryMode = TimePickerEntryMode.inputOnly;

WordBook? _wordBookForId(List<WordBook> books, String id) {
  for (final book in books) {
    if (book.id == id) return book;
  }
  return null;
}

/// Test-only accessor for [_wordBookForId].
WordBook? wordBookForIdForTest(List<WordBook> books, String id) =>
    _wordBookForId(books, id);

DateTime _studyPlanDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

/// Auto-derives the study-plan finish date from the wordbook size and the
/// daily new-word target, so the date stays bound to the daily pace instead
/// of being manually picked.
DateTime studyPlanAutoFinishDate({
  required int totalWords,
  required int dailyNewTarget,
  required DateTime today,
}) {
  final base = _studyPlanDateOnly(today);
  if (totalWords <= 0 || dailyNewTarget <= 0) {
    return base.add(const Duration(days: 30));
  }
  final days = (totalWords / dailyNewTarget).ceil().clamp(1, 3650);
  return base.add(Duration(days: days));
}

class _PlanInitializationKey {
  const _PlanInitializationKey({required this.id, required this.updatedAt});

  factory _PlanInitializationKey.fromPlan(StudyPlan plan) {
    return _PlanInitializationKey(id: plan.id, updatedAt: plan.updatedAt);
  }

  factory _PlanInitializationKey.fallback(String uid) {
    return _PlanInitializationKey(id: 'fallback:$uid', updatedAt: null);
  }

  final String id;
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return other is _PlanInitializationKey &&
        other.id == id &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

TimeOfDay parseStudyPlanReminderTime(String value) {
  final parts = value.split(':');
  final hour = int.tryParse(parts.first) ?? 20;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

class _StudyPlanAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StudyPlanAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const FallbackBackButton(fallbackLocation: '/settings'),
      title: Text(AppLocalizations.of(context).commonStudyPlan),
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
    required this.l10n,
  });

  final StudyBookInfo book;
  final int totalWords;
  final int completedWords;
  final double progress;
  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
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
          const SizedBox(height: AppTokens.s16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 11,
              backgroundColor: AppTheme.progressTrack(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              AppPill(
                label: l10n.wordbookWordsLearned(completedWords, totalWords),
                icon: AppIcons.school,
                variant: PillVariant.primary,
              ),
              AppPill(
                label: status == 'paused'
                    ? l10n.studyPlanPausedLabel
                    : l10n.studyPlanActive,
                icon: status == 'paused'
                    ? AppIcons.pauseCircle
                    : AppIcons.playCircle,
                variant: status == 'paused'
                    ? PillVariant.neutral
                    : PillVariant.success,
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
    required this.books,
    required this.userWords,
    required this.selectedId,
    required this.localeCode,
    required this.onSelected,
    required this.l10n,
  });

  final List<WordBook> books;
  final List<UserWord> userWords;
  final String selectedId;
  final String localeCode;
  final ValueChanged<String> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wordbookSwitch,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _books.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTokens.s12),
            itemBuilder: (context, index) {
              final book = _books[index];
              final selected = selectedId == book.id;
              final learned = learnedWordCountForBook(
                userWords: userWords,
                wordBookId: book.id,
                wordIds: book.wordIds.toSet(),
              );
              final progress = wordbookProgressValue(
                learnedWords: learned,
                totalWords: book.totalWords,
              );
              return _StudyBookCoverOption(
                book: book,
                localeCode: localeCode,
                learnedWords: learned,
                progress: progress,
                selected: selected,
                onTap: () => onSelected(book.id),
                l10n: l10n,
              );
            },
          ),
        ),
      ],
    );
  }

  List<WordBook> get _books {
    if (books.isNotEmpty) return books;
    final now = DateTime.now().toUtc();
    return [
      for (final book in studyBooks)
        WordBook(
          id: book.id,
          title: book.name,
          category: 'exam',
          examType: book.id,
          coverUrl: '',
          totalWords: 0,
          includedWords: 0,
          description: book.description,
          wordIds: const [],
          createdAt: now,
          words: const [],
        ),
    ];
  }
}

class _StudyBookCoverOption extends StatelessWidget {
  const _StudyBookCoverOption({
    required this.book,
    required this.localeCode,
    required this.learnedWords,
    required this.progress,
    required this.selected,
    required this.onTap,
    required this.l10n,
  });

  final WordBook book;
  final String localeCode;
  final int learnedWords;
  final double progress;
  final bool selected;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      // Keep the dark card when selected (inverting to a light fill made the
      // white progress bar vanish). Show selection as a "floating" highlight:
      // elevation + azure shadow, plus the azure border below.
      color: theme.colorScheme.surface,
      elevation: selected ? 6 : 0,
      shadowColor: AppTokens.azure,
      borderRadius: BorderRadius.circular(AppTokens.radiusTile + 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(AppTokens.s8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusTile + 4),
            border: Border.all(
              color: selected ? AppTokens.azure : AppTokens.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WordbookCoverCard(
                    examType: book.examType,
                    bookId: book.id,
                    title: book.nameFor(localeCode),
                    width: 56,
                    height: 74,
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.nameFor(localeCode),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          book.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                l10n.wordbookWordsLearned(learnedWords, book.totalWords),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              AppProgressBar(value: progress, solid: true, height: 5),
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
    required this.l10n,
  });

  final TextEditingController controller;
  final String label;
  final String helperText;
  final IconData icon;
  final int min;
  final int max;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        helperText: helperText,
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null) return l10n.studyPlanEnterNumber;
        if (parsed < min || parsed > max) {
          return l10n.studyPlanNumberRange(min, max);
        }
        return null;
      },
    );
  }
}

class _PlanDateTimeSection extends StatelessWidget {
  const _PlanDateTimeSection({
    required this.reminderTimeLabel,
    required this.onPickTime,
    required this.l10n,
  });

  final String reminderTimeLabel;
  final VoidCallback onPickTime;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s8,
      ),
      child: _PlanActionRow(
        icon: AppIcons.schedule,
        title: l10n.studyPlanReminderTime,
        subtitle: reminderTimeLabel,
        onTap: onPickTime,
      ),
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
    required this.l10n,
  });

  final bool isPaused;
  final bool isLoading;
  final VoidCallback onOpenWords;
  final VoidCallback onTogglePause;
  final VoidCallback onReset;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSecondaryButton(
          label: l10n.studyPlanViewWords,
          icon: AppIcons.style,
          onPressed: onOpenWords,
        ),
        const SizedBox(height: AppTokens.s12),
        AppSecondaryButton(
          label: isPaused ? l10n.studyPlanResume : l10n.studyPlanPause,
          icon: isPaused ? AppIcons.playCircle : AppIcons.pauseCircle,
          onPressed: isLoading ? null : onTogglePause,
        ),
        const SizedBox(height: AppTokens.s12),
        AppPrimaryButton(
          label: l10n.studyPlanReset,
          icon: AppIcons.restartAlt,
          onPressed: isLoading ? null : onReset,
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
              const Icon(AppIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLanguageTile extends StatelessWidget {
  const _CurrentLanguageTile({
    required this.currentLanguage,
    required this.l10n,
    required this.onTap,
  });

  final String currentLanguage;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Text(
            l10n.pickerChooseLanguage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          AppPill(
            label: languageLabel(currentLanguage, l10n),
            variant: PillVariant.primary,
          ),
          const Spacer(),
          Icon(
            AppIcons.chevronRight,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
