import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('生词添加 SnackBar 含查看 action', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) { ctx = c; return const SizedBox(); })),
    ));
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: const Text('added'),
      action: SnackBarAction(label: 'View', onPressed: () {}),
    ));
    await tester.pump();
    expect(find.text('View'), findsOneWidget);
  });
}
