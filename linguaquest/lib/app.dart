import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/local_notification_service.dart';

/// The app is locked to English. The target language being *learned* (Chinese,
/// etc.) is a separate concept (see AppState.targetLanguage); the UI itself is
/// English-only. The `zh`/`ms` ARB files and updateLocale() infra are kept
/// dormant for a future re-enable.
Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  return const Locale('en');
}

class LinguaQuestApp extends ConsumerWidget {
  const LinguaQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen<String?>(localNotificationTapRouteProvider, (previous, next) {
      if (next == null || next.isEmpty) return;
      router.go(next);
      ref.read(localNotificationTapRouteProvider.notifier).clear();
    });

    return MaterialApp.router(
      title: 'LinguaQuest',
      debugShowCheckedModeBanner: false,
      // Light-only: dark mode was removed (the theme was not production-ready).
      theme: AppTheme.light(),
      // Hard-locked to English regardless of device or persisted locale.
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (deviceLocale, supportedLocales) =>
          const Locale('en'),
      routerConfig: router,
    );
  }
}
