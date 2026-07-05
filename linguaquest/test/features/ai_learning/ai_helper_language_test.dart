// Task 7.5 / SVV AI-03,AI-04: AI helper text must name the CURRENT target
// language, not a hardcoded "Chinese". Under a Japanese scope the empty-state
// guidance and input hint should say "Japanese", never "Chinese".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/features/ai_learning/ai_chat_screen.dart';
import 'package:linguaquest/features/ai_learning/ai_sentence_analysis_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget screen) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => screen)],
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

Future<void> _pumpBootstrapped(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(_host(screen));
  await tester.pumpAndSettle();
  // The controller does not auto-bootstrap; drive it so the persisted
  // current_language scope is applied to state.
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await container.read(appControllerProvider.notifier).bootstrap();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Japanese scope: chat helper says Japanese, not Chinese',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'linguaquest.current_language': 'ja',
    });

    await _pumpBootstrapped(tester, const AiChatScreen());

    expect(find.textContaining('Japanese'), findsWidgets);
    expect(find.textContaining('Chinese'), findsNothing);
  });

  testWidgets('Japanese scope: sentence-analysis empty text says Japanese',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'linguaquest.current_language': 'ja',
    });

    await _pumpBootstrapped(tester, const AiSentenceAnalysisScreen());

    expect(find.textContaining('Japanese'), findsOneWidget);
    expect(find.textContaining('Chinese'), findsNothing);
  });

  testWidgets('Chinese scope: chat helper names Chinese', (tester) async {
    SharedPreferences.setMockInitialValues({
      'linguaquest.current_language': 'zh',
    });

    await _pumpBootstrapped(tester, const AiChatScreen());

    expect(find.textContaining('Chinese'), findsWidgets);
  });
}
