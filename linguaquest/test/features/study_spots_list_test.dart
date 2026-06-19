import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/data/models/study_spot.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/map/study_spots_list_screen.dart';

void main() {
  testWidgets('list shows saved spot names and total minutes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockStudySpotRepository();
    await repo.add(StudySpot(id: '', name: 'Library', latitude: 1, longitude: 2,
        studyMinutes: 30, createdAt: DateTime.utc(2026, 6, 19)));
    await repo.add(StudySpot(id: '', name: 'Cafe', latitude: 3, longitude: 4,
        studyMinutes: 15, createdAt: DateTime.utc(2026, 6, 18)));

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudySpotsListScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Cafe'), findsOneWidget);
    expect(find.textContaining('45'), findsWidgets); // total minutes
  });
}
