import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/features/training/passage_cloze_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('Passage cloze shows explicit loading text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const PassageClozeScreen(),
      ),
    ));
    // The first painted frame shows the loading state (_isLoading defaults to
    // true). _load() is scheduled via a post-frame callback and its future
    // resolves on a later microtask, so we assert before pumping again — an
    // extra pump would resolve the mock repo's synchronous future and clear it.
    expect(find.textContaining('AI is writing a short passage'), findsOneWidget);
  });
}
