import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/state/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/local_notification_service.dart';

/// Explanation language is independent from the selected learning wordbook.
Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  return supported.firstWhere(
    (locale) => locale.languageCode == deviceLocale?.languageCode,
    orElse: () => const Locale('en'),
  );
}

class LinguaQuestApp extends ConsumerWidget {
  const LinguaQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(
      appControllerProvider.select((s) => s.themeMode),
    );

    ref.listen<String?>(localNotificationTapRouteProvider, (previous, next) {
      if (next == null || next.isEmpty) return;
      router.go(next);
      ref.read(localNotificationTapRouteProvider.notifier).clear();
    });

    return MaterialApp.router(
      title: 'LinguaQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: ref.watch(appControllerProvider.select((s) => s.locale)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveAppLocale,
      routerConfig: router,
    );
  }
}
