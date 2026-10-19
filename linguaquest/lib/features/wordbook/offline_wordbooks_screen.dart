import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/app_controller.dart';
import '../../data/repositories/learning_repository.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class OfflineWordbooksScreen extends ConsumerStatefulWidget {
  const OfflineWordbooksScreen({super.key});
  @override
  ConsumerState<OfflineWordbooksScreen> createState() =>
      _OfflineWordbooksState();
}

class _OfflineWordbooksState extends ConsumerState<OfflineWordbooksScreen> {
  Set<String> _downloaded = {};
  String? _busy;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final repository = ref.read(learningRepositoryProvider);
    final ids = repository is OfflineWordbookRepository
        ? await (repository as OfflineWordbookRepository)
              .downloadedWordBookIds()
        : <String>{};
    if (mounted) setState(() => _downloaded = ids);
  }

  Future<void> _change(String id, {bool remove = false}) async {
    setState(() => _busy = id);
    final l10n = AppLocalizations.of(context);
    try {
      final repository = ref.read(learningRepositoryProvider);
      if (repository is! OfflineWordbookRepository) {
        throw UnsupportedError('Downloads require a connected build');
      }
      final repo = repository as OfflineWordbookRepository;
      if (remove) {
        await repo.removeDownloadedWordBook(id);
      } else {
        await repo.downloadWordBook(id);
      }
      await ref.read(appControllerProvider.notifier).refreshOfflineContent();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remove ? l10n.offlineBuiltIn : l10n.offlineDownloadSuccess,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.offlineDownloadFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final books =
        state.wordBooks
            .where((b) => b.language == state.currentLanguage)
            .toList()
          ..sort(
            (a, b) => a.id.endsWith('_starter')
                ? -1
                : b.id.endsWith('_starter')
                ? 1
                : 0,
          );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: Text(l10n.offlineWordbooks),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.offlineWordbooksHint),
          const SizedBox(height: 12),
          Text(
            l10n.offlineLocalProgress,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          for (final book in books)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.nameFor(l10n.localeName),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${book.words.length} ${l10n.commonWords} · ${_downloaded.contains(book.id) ? l10n.offlineDownloaded : l10n.offlineBuiltIn}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: _busy != null
                              ? null
                              : () => _change(book.id),
                          icon: _busy == book.id
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          label: Text(l10n.offlineDownload),
                        ),
                        if (_downloaded.contains(book.id))
                          TextButton(
                            onPressed: _busy != null
                                ? null
                                : () => _change(book.id, remove: true),
                            child: Text(l10n.offlineRemove),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
