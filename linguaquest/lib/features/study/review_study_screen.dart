import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/answer_sound_service.dart';
import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/top_notice.dart';
import '../../data/models/custom_word.dart';
import '../../l10n/generated/app_localizations.dart';

class ReviewStudyScreen extends ConsumerStatefulWidget {
  const ReviewStudyScreen({super.key});

  @override
  ConsumerState<ReviewStudyScreen> createState() => _ReviewStudyScreenState();
}

class _ReviewStudyScreenState extends ConsumerState<ReviewStudyScreen> {
  final List<CustomWord> _queue = [];
  final Set<String> _completedIds = {};
  final Set<String> _reinforcementIds = {};
  var _revealed = false;
  var _reviewedCount = 0;
  var _isSubmitting = false;
  var _queueInitialized = false;
  late final ProviderSubscription<AppState> _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = ref.listenManual<AppState>(appControllerProvider, (
      previous,
      next,
    ) {
      _syncQueue(next.dueWords, notify: previous != null);
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
    final currentWord = _queue.isEmpty ? null : _queue.first;
    final totalCount = _reviewedCount + _queue.length;

    return PopScope(
      canPop: !_needsExitConfirmation && !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _handleBack(context)),
          title: Text(l10n.reviewCenterTitle),
          actions: [
            TextButton(
              onPressed: () => _openReviewCenter(context),
              child: Text(l10n.reviewStudyManageQueue),
            ),
          ],
        ),
        bottomNavigationBar: currentWord == null
            ? null
            : _ReviewActions(
                isRevealed: _revealed,
                isSubmitting: _isSubmitting,
                onMissed: () => setState(() => _revealed = true),
                onContinueAfterReveal: () =>
                    _review(currentWord, isCorrect: false),
                onKnown: () => _review(currentWord, isCorrect: true),
                l10n: l10n,
              ),
        body: SafeArea(
          child: currentWord == null
              ? _QueueCompleteView(hasReviewed: _reviewedCount > 0, l10n: l10n)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    SectionHeader(
                      title: l10n.reviewStudyTodayTitle,
                      subtitle: l10n.reviewStudyTodaySubtitle,
                      trailing: PillLabel(
                        label: '${_reviewedCount + 1}/$totalCount',
                        icon: AppIcons.autoGraph,
                        color: AppTheme.cyan,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: totalCount == 0
                          ? 1
                          : (_reviewedCount / totalCount).clamp(0.0, 1.0),
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: AppTheme.progressTrack(context),
                    ),
                    const SizedBox(height: 18),
                    _ReviewWordCard(
                      word: currentWord,
                      isRevealed: _revealed,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 14),
                    _MemoryHintLine(
                      word: currentWord,
                      isRevealed: _revealed,
                      l10n: l10n,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  bool get _needsExitConfirmation =>
      _reviewedCount > 0 || _revealed || _reinforcementIds.isNotEmpty;

  Future<void> _handleBack(BuildContext activeContext) async {
    final canLeave = await _confirmExitIfNeeded(activeContext);
    if (!canLeave || !activeContext.mounted) return;
    if (activeContext.canPop()) {
      activeContext.pop();
      return;
    }
    activeContext.go('/home');
  }

  Future<void> _openReviewCenter(BuildContext activeContext) async {
    final canLeave = await _confirmExitIfNeeded(activeContext);
    if (!canLeave || !activeContext.mounted) return;
    activeContext.push('/review');
  }

  Future<bool> _confirmExitIfNeeded(BuildContext activeContext) async {
    if (_isSubmitting) return false;
    if (!_needsExitConfirmation) return true;
    final confirmed = await showDialog<bool>(
      context: activeContext,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).reviewStudyLeaveTitle),
        content: Text(AppLocalizations.of(context).reviewStudyLeaveContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).reviewStudyKeepReviewing),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(AppIcons.exitToApp),
            label: Text(AppLocalizations.of(context).commonLeave),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _review(CustomWord word, {required bool isCorrect}) async {
    if (_isSubmitting) return;
    unawaited(
      AnswerSoundService.play(
        isCorrect: isCorrect,
        enabled: ref.read(appControllerProvider).sensorySettings.soundEnabled,
      ),
    );
    setState(() => _isSubmitting = true);
    final isReinforcementPass =
        isCorrect && _reinforcementIds.contains(word.id);
    if (isReinforcementPass) {
      _completeCurrentReview(word, requeue: false);
      if (!mounted) return;
      showTopNotice(
        context,
        AppLocalizations.of(context).reviewStudyReinforced,
        icon: AppIcons.checkCircle,
      );
      return;
    }

    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .reviewWord(word.id, isCorrect);
    if (!mounted) return;
    if (!succeeded) {
      final message =
          ref.read(appControllerProvider).errorMessage ??
          AppLocalizations.of(context).reviewCenterUpdateFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isSubmitting = false);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final message = isCorrect
        ? l10n.reviewStudyRememberedMessage
        : l10n.reviewStudyNeedsReinforcementMessage;
    showTopNotice(
      context,
      message,
      icon: isCorrect ? AppIcons.checkCircle : AppIcons.replay,
    );
    _completeCurrentReview(word, requeue: !isCorrect);
  }

  void _syncQueue(List<CustomWord> dueWords, {required bool notify}) {
    final changed = _applyQueueSync(dueWords);
    if (!changed || !notify || !mounted) return;
    setState(() {});
  }

  bool _applyQueueSync(List<CustomWord> dueWords) {
    if (!_queueInitialized) {
      _queue
        ..clear()
        ..addAll(dueWords);
      _queueInitialized = true;
      return dueWords.isNotEmpty;
    }

    var changed = false;
    final queuedIds = _queue.map((word) => word.id).toSet();
    for (final word in dueWords) {
      if (_completedIds.contains(word.id) || queuedIds.contains(word.id)) {
        continue;
      }
      _queue.add(word);
      queuedIds.add(word.id);
      changed = true;
    }
    return changed;
  }

  CustomWord _latestWordSnapshot(CustomWord fallback) {
    final words = ref.read(appControllerProvider).reviewWords;
    for (final word in words) {
      if (word.id == fallback.id) return word;
    }
    return fallback;
  }

  void _completeCurrentReview(CustomWord word, {required bool requeue}) {
    setState(() {
      if (_queue.isNotEmpty && _queue.first.id == word.id) {
        _queue.removeAt(0);
      } else {
        _queue.removeWhere((item) => item.id == word.id);
      }
      _reviewedCount += 1;
      _revealed = false;
      _isSubmitting = false;
      if (requeue) {
        final snapshot = _latestWordSnapshot(word);
        _reinforcementIds.add(word.id);
        final insertIndex = _queue.length < 3 ? _queue.length : 3;
        _queue.insert(insertIndex, snapshot);
      } else {
        _completedIds.add(word.id);
        _reinforcementIds.remove(word.id);
      }
    });
  }
}

class _ReviewWordCard extends StatelessWidget {
  const _ReviewWordCard({
    required this.word,
    required this.isRevealed,
    required this.l10n,
  });

  final CustomWord word;
  final bool isRevealed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localeCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageCueBadge(cue: wordInitialCue(word.word), size: 66),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PillLabel(
                          label: displayCustomTag(word.tag, l10n: l10n),
                          icon: AppIcons.label,
                          color: AppTheme.teal,
                        ),
                        PillLabel(
                          label: word.source == 'target'
                              ? l10n.reviewCenterTargetWord
                              : l10n.reviewCenterCustomCard,
                          icon: word.source == 'target'
                              ? AppIcons.route
                              : AppIcons.style,
                          color: word.source == 'target'
                              ? AppTheme.cyan
                              : AppTheme.teal,
                        ),
                        PillLabel(
                          label: l10n.wordbookMasteryLevel(word.masteryLevel),
                          icon: AppIcons.psychologyAlt,
                          color: AppTheme.mango,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MasteryMeter(value: word.masteryLevel / 5),
          if (isRevealed) ...[
            const SizedBox(height: 18),
            Text(
              customWordMeaningFor(word, localeCode),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (word.exampleSentence.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.exampleSentence,
                style: textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ],
            if (word.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.note,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 18),
            Text(
              l10n.reviewStudyRecallHint,
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryHintLine extends StatelessWidget {
  const _MemoryHintLine({
    required this.word,
    required this.isRevealed,
    required this.l10n,
  });

  final CustomWord word;
  final bool isRevealed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconCueBadge(
          icon: isRevealed ? AppIcons.lightbulb : AppIcons.visibility,
          color: colorScheme.secondary,
          size: 38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isRevealed
                ? l10n.reviewStudyNextReview(
                    formatRelativeDue(word.nextReviewAt, DateTime.now(), l10n),
                  )
                : l10n.reviewStudyHiddenHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.42,
            ),
          ),
        ),
      ],
    );
  }
}

class _MasteryMeter extends StatelessWidget {
  const _MasteryMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 12,
        backgroundColor: AppTheme.progressTrack(context),
      ),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.isRevealed,
    required this.isSubmitting,
    required this.onMissed,
    required this.onContinueAfterReveal,
    required this.onKnown,
    required this.l10n,
  });

  final bool isRevealed;
  final bool isSubmitting;
  final VoidCallback onMissed;
  final VoidCallback onContinueAfterReveal;
  final VoidCallback onKnown;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    final compactOutlineStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: isRevealed
              ? FilledButton.icon(
                  onPressed: isSubmitting ? null : onContinueAfterReveal,
                  style: compactButtonStyle,
                  icon: const Icon(AppIcons.replay),
                  label: FittedBox(child: Text(l10n.reviewStudyReinforce)),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : onMissed,
                        style: compactOutlineStyle,
                        icon: const Icon(AppIcons.visibility),
                        label: FittedBox(child: Text(l10n.reviewCenterForgot)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isSubmitting ? null : onKnown,
                        style: compactButtonStyle,
                        icon: const Icon(AppIcons.check),
                        label: FittedBox(
                          child: Text(l10n.reviewCenterRemembered),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QueueCompleteView extends StatelessWidget {
  const _QueueCompleteView({required this.hasReviewed, required this.l10n});

  final bool hasReviewed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 88),
      children: [
        EmptyState(
          icon: AppIcons.checkCircle,
          title: hasReviewed
              ? l10n.reviewStudyCompleteTitle
              : l10n.reviewCenterEmptyTitle,
          message: hasReviewed
              ? l10n.reviewStudyCompleteMessage
              : l10n.reviewCenterEmptyMessage,
          action: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(AppIcons.home),
                label: Text(l10n.learningPathBackToHome),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/review'),
                icon: const Icon(AppIcons.style),
                label: Text(l10n.reviewStudyManageQueue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
