import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/features/map/study_map_screen.dart';

void main() {
  testWidgets('StudyMapScreen builds with a map and a save FAB', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudyMapScreen()),
    ));
    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
