import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/features/map/study_map_screen.dart';
import 'package:linguaquest/core/widgets/fallback_back_button.dart';

void main() {
  testWidgets('StudyMapScreen builds with a map and a save FAB', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudyMapScreen()),
    ));
    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('StudyMapScreen has a fallback back button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudyMapScreen()),
    ));
    await tester.pump();
    expect(find.byType(FallbackBackButton), findsOneWidget);
  });

  testWidgets('StudyMapScreen renders a heatmap CircleLayer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudyMapScreen()),
    ));
    await tester.pump();
    expect(find.byType(CircleLayer), findsOneWidget);
  });
}
