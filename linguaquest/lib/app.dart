import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/state/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/local_notification_service.dart';

/// Picks the locale to use when the user has NOT chosen one in-app: follow the
/// device/system language if it's a supported locale, otherwise fall back to
/// the app default (Chinese). Matching is by `languageCode` (region ignored),
/// which fits the app's three single-language locales (en/zh/ms).
Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  if (deviceLocale != null) {
    for (final candidate in supported) {
      if (candidate.languageCode == deviceLocale.languageCode) return candidate;
    }
  }
  return const Locale('zh');
}

class LinguaQuestApp extends ConsumerWidget {
  const LinguaQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(
      appControllerProvider.select((state) => state.themeMode),
    );
    final locale = ref.watch(
      appControllerProvider.select((state) => state.locale),
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
      // An explicit in-app language choice (state.locale) overrides everything;
      // when null, follow the system language via localeResolutionCallback.
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (locale != null) return locale;
        return resolveAppLocale(deviceLocale, supportedLocales);
      },
      routerConfig: router,
    );
  }
}
