import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/repositories/profile_repository.dart';
import '../../l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Public so tests can inject a fake repository via [ProviderScope] overrides.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    final client = ref.watch(apiClientProvider);
    return ApiProfileRepository(client);
  }
  final state = ref.watch(appControllerProvider);
  return MockProfileRepository(currentUserId: state.user?.uid);
});

final _publicProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
      final repo = ref.watch(profileRepositoryProvider);
      return repo.getPublicProfile(userId);
    });

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_publicProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(AppLocalizations.of(context).commonProfile),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ProfileError(
          error: err,
          onRetry: () => ref.invalidate(_publicProfileProvider(userId)),
        ),
        data: (profile) => _ProfileBody(profile: profile, userId: userId),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNotFound =
        error is DioException &&
        (error as DioException).response?.statusCode == 404;

    if (isNotFound) {
      // The user was deleted or their profile is private — a friendly, dead-end
      // empty state (no retry, since retrying will not change the outcome).
      return MascotEmptyState(
        title: l10n.publicProfileNotFoundTitle,
        message: l10n.publicProfileNotFoundMessage,
      );
    }

    return MascotEmptyState(
      title: l10n.publicProfileLoadFailedTitle,
      message: l10n.publicProfileLoadFailedMessage,
      action: FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

/// Simple nickname editor: a one-field dialog that updates the display name.
/// No avatar upload — nickname only, per product decision.
Future<void> _editNickname(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String current,
}) async {
  final l10n = AppLocalizations.of(context);
  final newName = await showDialog<String>(
    context: context,
    builder: (dialogContext) => _NicknameEditDialog(current: current),
  );
  if (newName == null || newName.isEmpty || newName == current) return;
  final error = await ref
      .read(appControllerProvider.notifier)
      .updateDisplayName(newName);
  if (!context.mounted) return;
  if (error != null) {
    final message = switch (error) {
      'not_signed_in' => l10n.profileEditNicknameSignInRequired,
      'empty' => l10n.profileEditNicknameEmpty,
      _ => l10n.profileEditNicknameSaveFailed,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    return;
  }
  ref.invalidate(_publicProfileProvider(userId));
}

class _NicknameEditDialog extends StatefulWidget {
  const _NicknameEditDialog({required this.current});

  final String current;

  @override
  State<_NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<_NicknameEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.profileEditNicknameTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        decoration: InputDecoration(labelText: l10n.authNickname),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile, required this.userId});

  final Map<String, dynamic> profile;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = profile['name'] as String? ?? 'User';
    final isOwner = profile['isOwner'] as bool? ?? false;
    final streak = profile['streak'] as int?;
    final stats = profile['stats'] as Map<String, dynamic>?;
    final achievements = (profile['achievements'] as List?)
        ?.cast<Map<String, dynamic>>();
    final wordbookProgress = profile['wordbookProgress'] as int?;
    final posts = (profile['posts'] as List?)?.cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        88,
      ),
      children: [
        // Header: avatar + name + owner badge. Owners get a pencil next to the
        // name to edit just their nickname (no navigation to settings).
        _ProfileHeader(
          name: name,
          isOwner: isOwner,
          onEditName: isOwner
              ? () => _editNickname(context, ref, userId: userId, current: name)
              : null,
        ),
        const SizedBox(height: AppTokens.s24),

        // Achievements row.
        if (achievements != null && achievements.isNotEmpty) ...[
          _SectionLabel(label: 'Achievements'),
          const SizedBox(height: AppTokens.s8),
          _AchievementRow(achievements: achievements),
          const SizedBox(height: AppTokens.s24),
        ],

        // Learning stats card.
        if (stats != null) ...[
          _SectionLabel(label: 'Learning Stats'),
          const SizedBox(height: AppTokens.s8),
          _StatsCard(stats: stats),
          const SizedBox(height: AppTokens.s24),
        ],

        // Streak pill.
        if (streak != null) ...[
          _SectionLabel(label: 'Streak'),
          const SizedBox(height: AppTokens.s8),
          Row(
            children: [
              AppPill(
                label: '$streak day${streak == 1 ? '' : 's'}',
                variant: PillVariant.streak,
                icon: AppIcons.localFireDepartment,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s24),
        ],

        // Wordbook progress bar.
        if (wordbookProgress != null) ...[
          _SectionLabel(label: 'Wordbook Progress'),
          const SizedBox(height: AppTokens.s8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$wordbookProgress words mastered',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppTokens.s8),
                AppProgressBar(value: (wordbookProgress / 100).clamp(0.0, 1.0)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s24),
        ],

        // Posts list.
        if (posts != null && posts.isNotEmpty) ...[
          _SectionLabel(label: 'Recent Posts'),
          const SizedBox(height: AppTokens.s8),
          _PostsList(posts: posts),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.isOwner,
    this.onEditName,
  });

  final String name;
  final bool isOwner;
  final VoidCallback? onEditName;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(RegExp(r'\s+'))
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppTokens.primarySoft,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTokens.azure,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onEditName != null)
                    IconButton(
                      icon: const Icon(AppIcons.edit, size: 20),
                      tooltip: AppLocalizations.of(
                        context,
                      ).profileEditNicknameTitle,
                      onPressed: onEditName,
                    ),
                ],
              ),
              if (isOwner) ...[
                const SizedBox(height: AppTokens.s4),
                const AppPill(label: 'You', variant: PillVariant.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievements});

  final List<Map<String, dynamic>> achievements;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: achievements.map((a) {
        final title = a['title'] as String? ?? 'Achievement';
        return AppPill(
          label: title,
          variant: PillVariant.success,
          icon: _iconForKey(a['iconKey'] as String?),
        );
      }).toList(),
    );
  }

  IconData? _iconForKey(String? key) {
    return switch (key) {
      'school' => AppIcons.school,
      'local_fire_department' => AppIcons.localFireDepartment,
      'star' => AppIcons.star,
      _ => null,
    };
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final learnedWords = stats['learnedWords'] as int? ?? 0;
    final masteredWords = stats['masteredWords'] as int? ?? 0;
    final totalDays = stats['totalDays'] as int? ?? 0;

    return AppCard(
      child: Column(
        children: [
          _StatRow(label: 'Words Learned', value: '$learnedWords'),
          const Divider(height: AppTokens.s16),
          _StatRow(label: 'Words Mastered', value: '$masteredWords'),
          const Divider(height: AppTokens.s16),
          _StatRow(label: 'Study Days', value: '$totalDays'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts});

  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0) const Divider(height: AppTokens.s16),
            Text(
              posts[i]['title'] as String? ?? posts[i]['body'] as String? ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
