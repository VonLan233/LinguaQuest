# Scenario Explore Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the SWE311-compulsory Map feature — a "Scenario Explore Map" screen under Discover that shows an OpenStreetMap base map, the user's GPS location, and a few tappable scenario pins.

**Architecture:** One full-screen route `/discover/map` rendering `flutter_map` (OSM tiles) + a `MarkerLayer` of const seed pins + a current-location marker. Device GPS is read through a `LocationSource` abstraction so widget tests inject a fake (real `geolocator` needs platform channels). Degrades gracefully: pins always render; denied/offline never crash.

**Tech Stack:** Flutter, Riverpod (app-wide; this screen is plain `StatefulWidget`), `flutter_map` + `latlong2` + `geolocator`, GoRouter, AppLocalizations (gen-l10n).

**Spec:** `docs/superpowers/specs/2026-06-25-map-explore-design.md`

## Global Constraints

- Library = `flutter_map` + `latlong2` + `geolocator`. **Not** google_maps_flutter.
- OSM tile URL `https://tile.openstreetmap.org/{z}/{x}/{y}.png`; `userAgentPackageName: 'com.example.linguaquest'` (the real `applicationId`).
- OSM attribution **required**: a `RichAttributionWidget` showing "© OpenStreetMap contributors".
- Default fallback center = `LatLng(39.9087, 116.3975)` (Beijing; keeps pins on-screen when GPS denied).
- Pins are a **local `const` list** — no backend, no network for pin data.
- New l10n keys go in `app_en.arb` (template) + `app_zh.arb` + `app_ms.arb`; run `flutter gen-l10n` and commit generated `lib/l10n/generated/`.
- All commands run from `linguaquest/`. `flutter analyze` clean + `flutter test` green before "done".
- Locked decisions: travel scenarios around Beijing; pins show inline `sampleWords` (no lesson deep-link in v1); screen folder `lib/features/explore/`; offline hint is a static footer note.
- `flutter_map` API note: this plan's code targets the v6+/v7 API (`MapOptions(initialCenter:, initialZoom:)`, `FlutterMap(mapController:, options:, children:)`, `Marker(point:, child:)`). If `pub add` resolves a different major, adjust constructor names accordingly and keep behavior identical.

---

### Task 1: Add dependencies + Android location permissions

**Files:**
- Modify: `linguaquest/pubspec.yaml` (via `flutter pub add`)
- Modify: `linguaquest/android/app/src/main/AndroidManifest.xml:2-3`

- [ ] **Step 1: Add the packages**

Run (from `linguaquest/`):
```bash
flutter pub add flutter_map latlong2 geolocator
```
Expected: pub resolves against SDK `^3.11.4` and writes three `dependencies:` entries; `Changed N dependencies!`.

- [ ] **Step 2: Add Android location permissions**

In `android/app/src/main/AndroidManifest.xml`, add two lines after the existing `POST_NOTIFICATIONS` permission (line 3), before `<application>`:
```xml
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
(`INTERNET` is already present for OSM tiles — leave it.)

- [ ] **Step 3: Verify pub get + analyze**

Run:
```bash
flutter pub get && flutter analyze
```
Expected: `No issues found!` (the new deps add no analyzer errors yet — nothing imports them).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml
git commit -m "build(map): add flutter_map/latlong2/geolocator + location permissions"
```

---

### Task 2: l10n keys for the map screen

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb`
- Modify: `linguaquest/lib/l10n/app_zh.arb`
- Modify: `linguaquest/lib/l10n/app_ms.arb`
- Generated: `linguaquest/lib/l10n/generated/` (via `flutter gen-l10n`)

**Interfaces:**
- Produces (used by Tasks 5 & 6): `l10n.exploreMapTitle`, `exploreMapSubtitle`, `exploreMapRecenter`, `exploreMapLocationDenied`, `exploreMapOfflineHint`, `exploreMapPinCta`, `exploreMapClose`, `exploreMapAttribution`, `exploreMapPinAirport`, `exploreMapPinRestaurant`, `exploreMapPinHotel`, `exploreMapPinStation`, `exploreMapPinMarket`, `exploreMapPinPark`.

- [ ] **Step 1: Add keys to `app_en.arb`**

Insert after the `"discoverCommunityPostsSubtitle"` entry (the files use plain `"key": "value"` pairs, no `@`-metadata for these):
```json
  "exploreMapTitle": "Explore Map",
  "exploreMapSubtitle": "Discover learning scenarios near you",
  "exploreMapRecenter": "Recenter on me",
  "exploreMapLocationDenied": "Location is off — showing the default area. Tap the locate button to enable.",
  "exploreMapOfflineHint": "Offline — map tiles may not load",
  "exploreMapPinCta": "Start this scenario",
  "exploreMapClose": "Close",
  "exploreMapAttribution": "© OpenStreetMap contributors",
  "exploreMapPinAirport": "Airport",
  "exploreMapPinRestaurant": "Restaurant",
  "exploreMapPinHotel": "Hotel",
  "exploreMapPinStation": "Train Station",
  "exploreMapPinMarket": "Market",
  "exploreMapPinPark": "Park",
```
(If the very next key after the insertion point already exists, ensure the trailing comma on the line before your block is present and your block ends with a comma since more keys follow.)

- [ ] **Step 2: Add the same keys to `app_zh.arb`**

```json
  "exploreMapTitle": "探索地图",
  "exploreMapSubtitle": "发现你附近的学习场景",
  "exploreMapRecenter": "回到我的位置",
  "exploreMapLocationDenied": "定位已关闭——正在显示默认区域。点击定位按钮以开启。",
  "exploreMapOfflineHint": "离线——地图瓦片可能无法加载",
  "exploreMapPinCta": "开始这个场景",
  "exploreMapClose": "关闭",
  "exploreMapAttribution": "© OpenStreetMap 贡献者",
  "exploreMapPinAirport": "机场",
  "exploreMapPinRestaurant": "餐厅",
  "exploreMapPinHotel": "酒店",
  "exploreMapPinStation": "火车站",
  "exploreMapPinMarket": "市场",
  "exploreMapPinPark": "公园",
```

- [ ] **Step 3: Add the same keys to `app_ms.arb`**

```json
  "exploreMapTitle": "Peta Jelajah",
  "exploreMapSubtitle": "Temui senario pembelajaran berhampiran anda",
  "exploreMapRecenter": "Pusatkan pada saya",
  "exploreMapLocationDenied": "Lokasi dimatikan — memaparkan kawasan lalai. Ketik butang lokasi untuk hidupkan.",
  "exploreMapOfflineHint": "Luar talian — jubin peta mungkin tidak dimuatkan",
  "exploreMapPinCta": "Mulakan senario ini",
  "exploreMapClose": "Tutup",
  "exploreMapAttribution": "© Penyumbang OpenStreetMap",
  "exploreMapPinAirport": "Lapangan Terbang",
  "exploreMapPinRestaurant": "Restoran",
  "exploreMapPinHotel": "Hotel",
  "exploreMapPinStation": "Stesen Kereta Api",
  "exploreMapPinMarket": "Pasar",
  "exploreMapPinPark": "Taman",
```

- [ ] **Step 4: Regenerate localizations + analyze**

Run:
```bash
flutter gen-l10n && flutter analyze
```
Expected: gen-l10n writes to `lib/l10n/generated/`; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_ms.arb lib/l10n/generated
git commit -m "feat(map): add explore-map l10n keys (en/zh/ms)"
```

---

### Task 3: ScenarioPin model, seed pins, and LocationSource (TDD)

**Files:**
- Create: `linguaquest/lib/features/explore/scenario_pin.dart`
- Create: `linguaquest/lib/features/explore/location_source.dart`
- Test: `linguaquest/test/features/explore/explore_data_test.dart`

**Interfaces:**
- Produces (used by Task 5): `ScenarioPin{ id, lat, lng, sampleWords, LatLng get location }`; `const List<ScenarioPin> scenarioPins`; `String scenarioPinTitle(AppLocalizations, String id)`; `abstract class LocationSource { Future<LatLng?> current(); }`; `GeolocatorLocationSource`; `FakeLocationSource(LatLng?)`.

- [ ] **Step 1: Write the failing test**

Create `test/features/explore/explore_data_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:linguaquest/features/explore/location_source.dart';
import 'package:linguaquest/features/explore/scenario_pin.dart';

void main() {
  test('scenarioPins are non-empty with valid coordinates and words', () {
    expect(scenarioPins, isNotEmpty);
    final ids = <String>{};
    for (final pin in scenarioPins) {
      expect(pin.id, isNotEmpty);
      expect(ids.add(pin.id), isTrue, reason: 'pin ids must be unique');
      expect(pin.lat, inInclusiveRange(-90, 90));
      expect(pin.lng, inInclusiveRange(-180, 180));
      expect(pin.sampleWords, isNotEmpty);
      expect(pin.location, isA<LatLng>());
    }
  });

  test('FakeLocationSource returns the injected value', () async {
    expect(await const FakeLocationSource(null).current(), isNull);
    final fix = LatLng(39.9087, 116.3975);
    expect(await FakeLocationSource(fix).current(), fix);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/features/explore/explore_data_test.dart
```
Expected: FAIL — `location_source.dart` / `scenario_pin.dart` don't exist (compile error).

- [ ] **Step 3: Create `scenario_pin.dart`**

```dart
import 'package:latlong2/latlong.dart';

import '../../l10n/generated/app_localizations.dart';

/// A learning-scenario location shown as a pin on the Explore map.
class ScenarioPin {
  const ScenarioPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.sampleWords,
  });

  final String id;
  final double lat;
  final double lng;
  final List<String> sampleWords;

  LatLng get location => LatLng(lat, lng);
}

/// Travel-scenario pins around Beijing. Local + const: render with no backend.
const List<ScenarioPin> scenarioPins = [
  ScenarioPin(id: 'airport', lat: 40.0799, lng: 116.6031, sampleWords: ['机场', '登机', '护照']),
  ScenarioPin(id: 'restaurant', lat: 39.9085, lng: 116.3975, sampleWords: ['菜单', '点菜', '买单']),
  ScenarioPin(id: 'hotel', lat: 39.9163, lng: 116.3972, sampleWords: ['房间', '前台', '退房']),
  ScenarioPin(id: 'station', lat: 39.9027, lng: 116.4279, sampleWords: ['车票', '站台', '出发']),
  ScenarioPin(id: 'market', lat: 39.9230, lng: 116.3884, sampleWords: ['蔬菜', '水果', '多少钱']),
  ScenarioPin(id: 'park', lat: 39.9319, lng: 116.4074, sampleWords: ['散步', '树', '湖']),
];

/// Resolves a pin id to its localized title (codegen'd l10n is not map-indexed).
String scenarioPinTitle(AppLocalizations l10n, String id) => switch (id) {
  'airport' => l10n.exploreMapPinAirport,
  'restaurant' => l10n.exploreMapPinRestaurant,
  'hotel' => l10n.exploreMapPinHotel,
  'station' => l10n.exploreMapPinStation,
  'market' => l10n.exploreMapPinMarket,
  'park' => l10n.exploreMapPinPark,
  _ => id,
};
```

- [ ] **Step 4: Create `location_source.dart`**

```dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Abstraction over device location so the map screen never calls geolocator
/// directly — widget tests inject [FakeLocationSource] (real geolocator needs
/// platform channels unavailable under `flutter test`).
abstract class LocationSource {
  Future<LatLng?> current();
}

/// Real implementation: requests permission and reads one GPS fix.
/// Returns null on any failure (services off, denied, denied-forever).
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<LatLng?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
}

/// Test double: returns whatever was injected.
class FakeLocationSource implements LocationSource {
  const FakeLocationSource(this._value);

  final LatLng? _value;

  @override
  Future<LatLng?> current() async => _value;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
flutter test test/features/explore/explore_data_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/explore/scenario_pin.dart lib/features/explore/location_source.dart test/features/explore/explore_data_test.dart
git commit -m "feat(map): scenario pin model + seed pins + location source abstraction"
```

---

### Task 4: Add map icons to AppIcons

**Files:**
- Modify: `linguaquest/lib/core/theme/app_icons.dart`

**Interfaces:**
- Produces (used by Task 5): `AppIcons.myLocation`, `AppIcons.place`.

- [ ] **Step 1: Add the two icons**

In `lib/core/theme/app_icons.dart`, near the existing `explore`/`travelExplore` entries, add (follow the existing `static const IconData x = Symbols.x_rounded;` pattern):
```dart
  static const IconData myLocation = Symbols.my_location_rounded;
  static const IconData place = Symbols.place_rounded;
```

- [ ] **Step 2: Verify analyze**

Run:
```bash
flutter analyze lib/core/theme/app_icons.dart
```
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_icons.dart
git commit -m "feat(map): add myLocation + place icons"
```

---

### Task 5: ExploreMapScreen + widget test (TDD)

**Files:**
- Create: `linguaquest/lib/features/explore/explore_map_screen.dart`
- Test: `linguaquest/test/features/explore/explore_map_screen_test.dart`

**Interfaces:**
- Consumes: `ScenarioPin`, `scenarioPins`, `scenarioPinTitle`, `LocationSource`, `FakeLocationSource` (Task 3); `AppIcons.myLocation`, `AppIcons.place` (Task 4); `l10n.exploreMap*` (Task 2).
- Produces (used by Task 6): `class ExploreMapScreen extends StatefulWidget` with `const ExploreMapScreen({super.key, LocationSource? locationSource})`.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/explore/explore_map_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/features/explore/explore_map_screen.dart';
import 'package:linguaquest/features/explore/location_source.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

Widget _harness(LocationSource source) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ExploreMapScreen(locationSource: source),
    );

void main() {
  testWidgets('renders map + current-location marker when located', (tester) async {
    await tester.pumpWidget(_harness(FakeLocationSource(LatLng(39.9087, 116.3975))));
    await tester.pump(); // let the location future resolve
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byKey(const ValueKey('current-location')), findsOneWidget);
  });

  testWidgets('no crash + denied banner + no current marker when location null',
      (tester) async {
    await tester.pumpWidget(_harness(const FakeLocationSource(null)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byKey(const ValueKey('current-location')), findsNothing);
    expect(find.byIcon(AppIcons.warningAmber), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
flutter test test/features/explore/explore_map_screen_test.dart
```
Expected: FAIL — `explore_map_screen.dart` does not exist.

- [ ] **Step 3: Create `explore_map_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';
import 'location_source.dart';
import 'scenario_pin.dart';

/// Scenario Explore Map — OSM base map + GPS marker + seeded scenario pins.
/// Degrades gracefully: pins always render; denied/offline never crash.
class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key, this.locationSource});

  /// Injected in tests; defaults to the real geolocator-backed source.
  final LocationSource? locationSource;

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  static const LatLng _defaultCenter = LatLng(39.9087, 116.3975);

  final MapController _mapController = MapController();
  late final LocationSource _location;
  LatLng? _userLatLng;
  bool _locationResolved = false;

  @override
  void initState() {
    super.initState();
    _location = widget.locationSource ?? const GeolocatorLocationSource();
    _resolveLocation(recenter: false);
  }

  Future<void> _resolveLocation({required bool recenter}) async {
    final latLng = await _location.current();
    if (!mounted) return;
    setState(() {
      _userLatLng = latLng;
      _locationResolved = true;
    });
    if (recenter && latLng != null) {
      _mapController.move(latLng, 15);
    }
  }

  void _openPinSheet(ScenarioPin pin) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: scenarioPinTitle(l10n, pin.id)),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  for (final word in pin.sampleWords)
                    AppPill(label: word, variant: PillVariant.primary),
                ],
              ),
              const SizedBox(height: AppTokens.s16),
              AppPrimaryButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: AppIcons.check,
                label: l10n.exploreMapClose,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final center = _userLatLng ?? _defaultCenter;
    final locationDenied = _locationResolved && _userLatLng == null;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: Text(l10n.exploreMapTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _resolveLocation(recenter: true),
        tooltip: l10n.exploreMapRecenter,
        child: const Icon(AppIcons.myLocation),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.linguaquest',
              ),
              MarkerLayer(
                markers: [
                  for (final pin in scenarioPins)
                    Marker(
                      point: pin.location,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        key: ValueKey('pin-${pin.id}'),
                        onTap: () => _openPinSheet(pin),
                        child: Icon(
                          AppIcons.place,
                          color: AppTokens.coralColor(context),
                          size: 40,
                        ),
                      ),
                    ),
                  if (_userLatLng != null)
                    Marker(
                      point: _userLatLng!,
                      width: 28,
                      height: 28,
                      child: Icon(
                        AppIcons.myLocation,
                        key: const ValueKey('current-location'),
                        color: AppTokens.azure,
                        size: 26,
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(l10n.exploreMapAttribution),
                ],
              ),
            ],
          ),
          if (locationDenied)
            Positioned(
              top: AppTokens.s12,
              left: AppTokens.s12,
              right: AppTokens.s12,
              child: AppCard(
                child: Row(
                  children: [
                    Icon(
                      AppIcons.warningAmber,
                      color: AppTokens.coralColor(context),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(child: Text(l10n.exploreMapLocationDenied)),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: AppTokens.s12,
            left: AppTokens.s12,
            child: Text(
              l10n.exploreMapOfflineHint,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the widget test to verify it passes**

Run:
```bash
flutter test test/features/explore/explore_map_screen_test.dart
```
Expected: PASS (2 tests). If `flutter_map`'s API names differ from the resolved major (e.g. `center`/`zoom` instead of `initialCenter`/`initialZoom`), adjust per the Global Constraints note and re-run.

- [ ] **Step 5: Analyze**

Run:
```bash
flutter analyze lib/features/explore test/features/explore
```
Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/explore/explore_map_screen.dart test/features/explore/explore_map_screen_test.dart
git commit -m "feat(map): ExploreMapScreen with OSM tiles, pins, GPS marker + widget test"
```

---

### Task 6: Wire navigation — Discover card + route

**Files:**
- Modify: `linguaquest/lib/features/discover/discover_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart:17` (imports) and `:232` (routes)

**Interfaces:**
- Consumes: `ExploreMapScreen` (Task 5); `l10n.exploreMapTitle` (Task 2); `AppIcons.travelExplore` (existing).

- [ ] **Step 1: Add the Discover entry card**

In `lib/features/discover/discover_screen.dart`, after the `CompactEntryCard` for `discoverCommunityPosts` (and its following `SizedBox` — add a `SizedBox` first), insert:
```dart
        const SizedBox(height: AppTokens.s12),
        CompactEntryCard(
          icon: AppIcons.travelExplore,
          title: l10n.exploreMapTitle,
          color: AppTokens.azure,
          onTap: () => context.push('/discover/map'),
        ),
```

- [ ] **Step 2: Register the route**

In `lib/core/routing/app_router.dart`, add the import near the other discover imports (after line 19):
```dart
import '../../features/explore/explore_map_screen.dart';
```
Then add the route after the `/discover/community` `GoRoute` (after line 232):
```dart
      GoRoute(
        path: '/discover/map',
        builder: (context, state) => const ExploreMapScreen(),
      ),
```

- [ ] **Step 3: Analyze**

Run:
```bash
flutter analyze lib/features/discover/discover_screen.dart lib/core/routing/app_router.dart
```
Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/discover/discover_screen.dart lib/core/routing/app_router.dart
git commit -m "feat(map): wire Explore Map into Discover tab + /discover/map route"
```

---

### Task 7: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Full static analysis**

Run:
```bash
flutter analyze
```
Expected: `No issues found!`.

- [ ] **Step 2: Full test suite**

Run:
```bash
flutter test
```
Expected: All tests pass, including the two new explore test files and the pre-existing suite (`app_tokens_test.dart`, `widget_test.dart`, etc.).

- [ ] **Step 3: Manual / screenshot verification (for the report)**

Run:
```bash
flutter run
```
Then: open the **Discover** tab → tap **Explore Map**. Confirm: OSM tiles load, scenario pins are tappable (bottom sheet with words + Close), the recenter FAB requests location and drops the blue marker, and "© OpenStreetMap contributors" is visible. Then deny location and confirm the denied banner shows and pins still render. Capture the screenshot for the report.

- [ ] **Step 4: Build the release APK (smoke)**

Run:
```bash
flutter build apk --release
```
Expected: build succeeds (verifies the new permissions + geolocator gradle integration). If `minSdk` is too low, bump it in `android/app/build.gradle.kts` and rebuild.

---

## Notes for the implementer

- **Don't** block the first frame on location — the map renders at the default center immediately, then recenters when the fix resolves. This is what makes the screen testable and crash-safe.
- The pin markers use `ValueKey('pin-<id>')`; the current-location marker uses `ValueKey('current-location')`. Tests rely on these.
- If `flutter test` hangs, it's likely `pumpAndSettle` against the map — the provided tests use explicit `pump()` calls; keep them.
- v1 deliberately shows inline `sampleWords` on pin tap (no lesson deep-link). Deep-linking a pin to a real `Lesson` is a future enhancement, not part of this plan.
