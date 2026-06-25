import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/shell/app_drawer.dart';

void main() {
  testWidgets('AppDrawer lists Map and About entries', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(drawer: const AppDrawer(), body: const SizedBox()),
      onGenerateRoute: (_) => null,
    ));
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Study Map'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
