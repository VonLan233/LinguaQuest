import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/generated/app_localizations.dart';

class MyFavoritesScreen extends ConsumerStatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  ConsumerState<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends ConsumerState<MyFavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).refreshFavoritedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final posts = ref.watch(
      appControllerProvider.select((s) => s.favoritedPosts),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverMyFavorites)),
      body: posts.isEmpty
          ? Center(child: Text(l10n.favoritesEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(AppTokens.s20),
              itemCount: posts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppTokens.s12),
              itemBuilder: (context, i) {
                final post = posts[i];
                return AppCard(
                  onTap: () => context.push('/forum/posts/${post.id}'),
                  padding: const EdgeInsets.all(AppTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Text(
                        post.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
