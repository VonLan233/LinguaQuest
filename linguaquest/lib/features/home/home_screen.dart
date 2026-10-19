import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/study_cat.dart';
import '../../l10n/generated/app_localizations.dart';

int wordOfDayIndex(int epochDay, int wordCount) =>
    wordCount <= 0 ? 0 : epochDay % wordCount;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final book = state.currentWordBook;
    final total = state.isStudyPlanPaused
        ? 0
        : state.dailyNewTarget + state.dailyReviewTarget;
    final done = state.todayLearningWords + state.todayReviewWordIds.length;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final newLeft = (state.dailyNewTarget - state.todayLearningWords).clamp(
      0,
      state.dailyNewTarget,
    );
    final words = state.currentLesson?.words ?? [];
    final word = words.isEmpty
        ? null
        : words[wordOfDayIndex(
            DateTime.now().millisecondsSinceEpoch ~/
                Duration.millisecondsPerDay,
            words.length,
          )];
    final canStudy =
        !state.isStudyPlanPaused &&
        (state.availableNewWords.isNotEmpty || state.reviewQueue.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: Icon(AppIcons.menu, color: colors.onSurface),
              ),
            ),
            const Expanded(
              child: Text(
                'LinguaQuest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              Icons.local_fire_department_outlined,
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: 3),
            Text(
              '${state.user?.streak ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              key: const ValueKey('home-search'),
              tooltip: l10n.commonSearch,
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: l10n.homeNotifications,
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                label: Text('${state.unreadNotificationCount}'),
                isLabelVisible: state.unreadNotificationCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          '${l10n.homeGreeting}, ${displayUserName(state.user, l10n: l10n)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.dailyEncouragement,
          key: const ValueKey('daily-encouragement'),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 19,
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isStudyPlanPaused
                        ? l10n.homePlanPaused
                        : l10n.dailyTaskTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.dailyTaskHint, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const StudyCat(size: 58),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => showLanguageWordbookPicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    book?.nameFor(l10n.localeName) ?? l10n.commonWordbook,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.expand_more, color: colors.primary),
              ],
            ),
          ),
        ),
        Text(
          '${languageLabel(l10n.localeName, l10n)} → ${languageLabel(state.currentLanguage, l10n)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Text(l10n.homeTodayProgress, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$done',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: colors.primary,
                ),
              ),
              TextSpan(
                text: ' / $total',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppProgressBar(
          value: progress,
          height: 3,
          solid: true,
          solidColor: colors.primary,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.commonNew} $newLeft · ${l10n.commonReview} ${state.reviewQueue.length}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (!state.isStudyPlanPaused)
              TextButton(
                key: const ValueKey('home-adjust-plan'),
                onPressed: () => context.push('/settings/study-plan'),
                child: Text(l10n.homeAdjustPlan),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          key: const ValueKey('home-continue'),
          label: state.isStudyPlanPaused
              ? l10n.homeAdjustPlan
              : l10n.continueLearning,
          icon: Icons.arrow_forward,
          onPressed: state.isStudyPlanPaused
              ? () => context.push('/settings/study-plan')
              : canStudy
              ? () => context.push(
                  newLeft > 0 && state.availableNewWords.isNotEmpty
                      ? '/study/new'
                      : '/study/review',
                )
              : null,
        ),
        const SizedBox(height: 18),
        _HomeEntry(
          key: const ValueKey('home-review'),
          icon: Icons.history_rounded,
          title: l10n.homeReviewOnly,
          subtitle: '${state.reviewQueue.length} ${l10n.commonWords}',
          route: '/study/review',
        ),
        const SizedBox(height: 10),
        _HomeEntry(
          icon: Icons.chat_bubble_outline_rounded,
          title: l10n.homeAiHelp,
          subtitle: l10n.homeAiHelpHint,
          route: '/ai-learning',
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              _HomeLink(
                icon: Icons.menu_book_outlined,
                title: l10n.homeWordbookShortcut,
                route: '/wordbook',
              ),
              _HomeLink(
                icon: Icons.download_for_offline_outlined,
                title: l10n.offlineWordbooks,
                route: '/offline-wordbooks',
              ),
              _HomeLink(
                icon: Icons.article_outlined,
                title: l10n.homeDailyArticle,
                route: '/reading',
              ),
              _HomeLink(
                icon: Icons.route_outlined,
                title: l10n.homeLearningPath,
                route: '/learn',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (word == null) ...[
          AppCard(
            onTap: () => context.push('/wordbook'),
            child: Text(l10n.homeOpenWordCard),
          ),
          const SizedBox(height: 24),
        ],
        if (word != null) ...[
          GestureDetector(
            onTap: () => context.push('/wordbook/${word.id}'),
            child: Text(l10n.homeWordOfDay, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => context.push('/wordbook/${word.id}'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(word.primaryDefinitionFor(l10n.localeName)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeWeakWords,
                style: theme.textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/study/review'),
              child: Text(l10n.commonReview),
            ),
          ],
        ),
        if (state.weakWords.isEmpty)
          AppCard(
            child: Row(
              children: [
                const StudyCat(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => context.push('/study/review'),
                    child: Text(l10n.commonReview),
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                for (final weak in state.weakWords.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(weak.word),
                    subtitle: Text(customWordMeaningFor(weak, l10n.localeName)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/study/review'),
                  ),
                if (state.weakWords.length > 3)
                  TextButton(
                    key: const ValueKey('home-see-all-mistakes'),
                    onPressed: () => context.push('/mistake-book'),
                    child: Text(l10n.commonViewAll),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HomeEntry extends StatelessWidget {
  const _HomeEntry({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title, subtitle, route;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLink extends StatelessWidget {
  const _HomeLink({
    required this.icon,
    required this.title,
    required this.route,
  });
  final IconData icon;
  final String title, route;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: () => context.push(route),
  );
}
