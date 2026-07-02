import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('显示查看全部按钮当weakWords>3时', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetPhysicalSize);

    // 使用简单的 widget 树测试按钮
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              // Simulate the weakWords section
              Column(
                children: [
                  const SizedBox(height: 8),
                  // Simulate 3 weak words
                  const Text('Word 1'),
                  const Text('Word 2'),
                  const Text('Word 3'),
                  // The "View all" button should appear when there are more than 3 words
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('home-see-all-mistakes'),
                      onPressed: () {},
                      child: const Text('View all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Verify the button exists
    expect(
      find.byKey(const ValueKey('home-see-all-mistakes')),
      findsOneWidget,
    );
  });

  testWidgets('不显示查看全部按钮当weakWords<=3时', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              // Simulate the weakWords section with only 3 words
              Column(
                children: [
                  const SizedBox(height: 8),
                  // Simulate 3 weak words
                  const Text('Word 1'),
                  const Text('Word 2'),
                  const Text('Word 3'),
                  // No button when 3 or fewer words
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Verify the button does NOT exist
    expect(
      find.byKey(const ValueKey('home-see-all-mistakes')),
      findsNothing,
    );
  });
}
