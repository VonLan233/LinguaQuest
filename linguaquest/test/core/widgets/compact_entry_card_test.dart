import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/core/widgets/compact_entry_card.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CompactEntryCard', () {
    testWidgets('renders the title and its leading icon', (tester) async {
      await tester.pumpWidget(
        _host(
          const CompactEntryCard(
            icon: AppIcons.school,
            title: 'Last One Standing',
            color: Colors.red,
          ),
        ),
      );
      expect(find.text('Last One Standing'), findsOneWidget);
      expect(find.byIcon(AppIcons.school), findsOneWidget);
    });

    testWidgets('shows a chevron when tappable and no trailing is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CompactEntryCard(
            icon: AppIcons.school,
            title: 'Tap me',
            color: Colors.blue,
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    });

    testWidgets('prefers an explicit trailing widget over the chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CompactEntryCard(
            icon: AppIcons.school,
            title: 'Has trailing',
            color: Colors.blue,
            onTap: () {},
            trailing: const Text('Coming Soon'),
          ),
        ),
      );
      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          CompactEntryCard(
            icon: AppIcons.school,
            title: 'Tap target',
            color: Colors.green,
            onTap: () => tapped++,
          ),
        ),
      );
      await tester.tap(find.text('Tap target'));
      expect(tapped, 1);
    });

    testWidgets('disabled card has no chevron and is not tappable', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(
          CompactEntryCard(
            icon: AppIcons.school,
            title: 'Disabled',
            color: Colors.grey,
            enabled: false,
            onTap: () => tapped++,
            trailing: const Text('Coming Soon'),
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      expect(tapped, 0);
      // Trailing still shows (status), but no navigation chevron.
      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    });
  });
}
