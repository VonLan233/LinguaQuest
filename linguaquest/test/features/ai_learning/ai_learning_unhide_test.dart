import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/features/ai_learning/ai_learning_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadL10n() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Widget buildApp() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AiLearningScreen(),
        ),
        GoRoute(
          path: '/ai-chat',
          builder: (context, state) => const Scaffold(body: Text('ai-chat')),
        ),
        GoRoute(
          path: '/ai-analysis',
          builder: (context, state) => const Scaffold(body: Text('ai-analysis')),
        ),
        GoRoute(
          path: '/ai-cloze',
          builder: (context, state) => const Scaffold(body: Text('ai-cloze')),
        ),
        GoRoute(
          path: '/ai-writing-review',
          builder: (context, state) =>
              const Scaffold(body: Text('ai-writing-review')),
        ),
        GoRoute(
          path: '/ai-tutor',
          builder: (context, state) => const Scaffold(body: Text('ai-tutor')),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
  }

  testWidgets(
    'aiLearningStatusSoon appears 0 times; Available appears; In Planning appears exactly twice',
    (tester) async {
      final l10n = await loadL10n();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // aiLearningStatusSoon ("Coming Soon") should not appear at all — check
      // before and after scrolling to catch any pill anywhere in the list.
      expect(find.text(l10n.aiLearningStatusSoon), findsNothing);

      // Scroll to bottom so all rows are rendered.
      await tester.scrollUntilVisible(
        find.text(l10n.aiLearningToolSentence),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // "Coming Soon" still must not appear after scroll.
      expect(find.text(l10n.aiLearningStatusSoon), findsNothing);

      // aiLearningStatusAvailable ("Available") should appear for the 4 working tools
      expect(find.text(l10n.aiLearningStatusAvailable), findsWidgets);

      // aiLearningStatusPlanning ("In Planning") should appear exactly twice (Confusion + Sentence)
      expect(find.text(l10n.aiLearningStatusPlanning), findsNWidgets(2));
    },
  );
}
