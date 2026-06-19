import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';

class StudySpotsListScreen extends ConsumerStatefulWidget {
  const StudySpotsListScreen({super.key});
  @override
  ConsumerState<StudySpotsListScreen> createState() =>
      _StudySpotsListScreenState();
}

class _StudySpotsListScreenState extends ConsumerState<StudySpotsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).loadStudySpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spots =
        ref.watch(appControllerProvider.select((s) => s.studySpots));
    final totalMinutes =
        spots.fold<int>(0, (sum, s) => sum + s.studyMinutes);
    return Scaffold(
      appBar: AppBar(title: const Text('Study Spots')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s16),
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total study minutes',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('$totalMinutes',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          for (final s in spots)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s8),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place),
                  title: Text(s.name),
                  subtitle: Text(
                      '${s.studyMinutes} min · ${s.latitude.toStringAsFixed(3)}, ${s.longitude.toStringAsFixed(3)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .deleteStudySpot(s.id),
                  ),
                ),
              ),
            ),
          if (spots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: Center(child: Text('No study spots yet.')),
            ),
        ],
      ),
    );
  }
}
