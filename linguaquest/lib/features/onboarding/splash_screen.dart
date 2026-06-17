import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/brand_mark.dart';
import '../../l10n/generated/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.86,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _start();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await ref.read(appControllerProvider.notifier).bootstrap();
    if (!mounted) return;
    final state = ref.read(appControllerProvider);
    if (!state.isBootstrapped && state.errorMessage != null) return;
    if (!mounted) return;
    context.go(state.isAuthenticated ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final failed =
        !state.isLoading && !state.isBootstrapped && state.errorMessage != null;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(scale: _scale, child: const BrandMark(size: 118)),
            const SizedBox(height: 22),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text(
                    'LinguaQuest',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.ink,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.splashTagline,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (failed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppPrimaryButton(
                      onPressed: _start,
                      icon: AppIcons.refresh,
                      label: l10n.commonRetry,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  child: LinearProgressIndicator(
                    value: state.isLoading ? null : 1,
                    minHeight: 10,
                    backgroundColor: AppTheme.progressTrack(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
