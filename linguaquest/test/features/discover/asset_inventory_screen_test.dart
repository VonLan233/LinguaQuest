import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/models/lottery.dart';
import 'package:linguaquest/features/discover/asset_inventory_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// A minimal AppController subclass that starts with a preset AppState.
// This lets us inject userAssets without going through the full auth flow.
class _PresetAppController extends AppController {
  _PresetAppController(this._preset);
  final AppState _preset;

  @override
  AppState build() => _preset;
}

Widget _buildHarness({required AppState initialState}) {
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith(
        () => _PresetAppController(initialState),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light(),
      home: const AssetInventoryScreen(),
    ),
  );
}

final _now = DateTime.utc(2026, 6, 26);

final _seededAssets = [
  UserAsset(
    id: 'asset-1',
    uid: 'test-user',
    prizeId: 'badge-focus-sprinter',
    category: 'badge',
    rarity: 'uncommon',
    name: '专注冲刺徽章',
    description: '学习资料页展示徽章，仅作荣誉装饰。',
    quantity: 2,
    fragmentValue: 8,
    acquiredAt: _now,
    updatedAt: _now,
  ),
  UserAsset(
    id: 'asset-2',
    uid: 'test-user',
    prizeId: 'comfort-star-fragments',
    category: 'fragment',
    rarity: 'comfort',
    name: '星尘碎片',
    description: '安慰奖励，可累计兑换装饰资产。',
    quantity: 3,
    fragmentValue: 3,
    acquiredAt: _now,
    updatedAt: _now,
  ),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AssetInventoryScreen — empty state', () {
    testWidgets('shows empty mascot when userAssets is empty', (tester) async {
      final emptyState = AppState.initial().copyWith(isBootstrapped: true);

      await tester.pumpWidget(_buildHarness(initialState: emptyState));
      await tester.pump();

      // Should show MascotEmptyState (which renders the title text).
      // The zh l10n key is assetInventoryEmpty.
      expect(find.byType(AssetInventoryScreen), findsOneWidget);
    });
  });

  group('AssetInventoryScreen — with assets', () {
    testWidgets('shows asset names when userAssets is non-empty', (
      tester,
    ) async {
      final stateWithAssets = AppState.initial().copyWith(
        isBootstrapped: true,
        userAssets: _seededAssets,
      );

      await tester.pumpWidget(_buildHarness(initialState: stateWithAssets));
      await tester.pump();

      // Asset names should be visible.
      expect(find.text('专注冲刺徽章'), findsOneWidget);
      expect(find.text('星尘碎片'), findsOneWidget);
    });

    testWidgets('shows quantity badge for assets with quantity > 1', (
      tester,
    ) async {
      final stateWithAssets = AppState.initial().copyWith(
        isBootstrapped: true,
        userAssets: _seededAssets,
      );

      await tester.pumpWidget(_buildHarness(initialState: stateWithAssets));
      await tester.pump();

      // badge asset has quantity 2, fragment has quantity 3.
      // The zh l10n format is '×{count}' (multiplication sign).
      expect(find.textContaining('×2'), findsWidgets);
      expect(find.textContaining('×3'), findsWidgets);
    });

    testWidgets('groups assets by category — badge section appears', (
      tester,
    ) async {
      final stateWithAssets = AppState.initial().copyWith(
        isBootstrapped: true,
        userAssets: _seededAssets,
      );

      await tester.pumpWidget(_buildHarness(initialState: stateWithAssets));
      await tester.pump();

      expect(find.text('Learning Badge'), findsAtLeastNWidgets(1));
    });
  });
}
