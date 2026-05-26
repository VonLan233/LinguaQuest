import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_start);
  }

  Future<void> _start() async {
    await ref.read(appControllerProvider.notifier).bootstrap();
    if (!mounted) return;
    final state = ref.read(appControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.go(state.isAuthenticated ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LogoMark(),
            const SizedBox(height: 20),
            Text(
              'LinguaQuest',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Image cards. Guided paths. Smart review.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(minHeight: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepTeal, AppTheme.teal, AppTheme.cyan],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.coral.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.language, color: Colors.white, size: 42),
          Positioned(right: 12, bottom: 10, child: Text('✨')),
        ],
      ),
    );
  }
}
