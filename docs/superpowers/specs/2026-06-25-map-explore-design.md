# Design Spec — Scenario Explore Map (SWE311 compulsory Map feature)

- **Date:** 2026-06-25
- **Status:** Draft (design only — no code in this document)
- **Author:** Claude (design agent)
- **Project:** LinguaQuest (Flutter, English-UI app for learning Chinese / HSK vocabulary, offline-first, optional Dart backend)
- **Branch context:** feature work branches from `main`

---

## 1. Overview & rubric mapping

### 1.1 Why this exists

The SWE311 final-project rubric makes a **Map feature COMPULSORY**. Exact rubric wording:

> **Map Feature:** Use OpenStreetMap or another mapping API to display or track location.

This spec designs **one** self-contained map screen — the **Scenario Explore Map** — that lives under the existing **Discover** tab. The screen:

1. **Tracks the user's current location** via the device GPS (geolocator), drawing a "you are here" marker, and
2. **Displays locations** as a small set of seeded *scenario / culture pins* on an OpenStreetMap base map.

Either of these independently satisfies the rubric's "display **or** track location". We do **both** so the feature still visibly works when GPS permission is denied (pins still display) — graceful degradation is a first-class requirement here because the report screenshot must show a working map.

### 1.2 The graded screenshot

The report will include a screenshot of `ExploreMapScreen` showing:

- The OSM tile base map (streets visible),
- The blue "current location" marker (or, if GPS denied, the default-center view + an "location off" banner),
- 4–6 scenario pins,
- The **© OpenStreetMap contributors** attribution (rubric/licence requirement — see §9).

Correctness and "it visibly works" outrank product cleverness. This is intentionally **one solid, demonstrable map screen**, not a mapping platform.

---

## 2. Scope

### In scope

- A new route `/discover/map` and a Discover-list entry card that opens it.
- `ExploreMapScreen`: `FlutterMap` + OSM `TileLayer` + `MarkerLayer` (pins + current-location marker) + a "recenter on me" `FloatingActionButton` + a pin-detail bottom sheet (AppCard styling) + RichAttributionWidget.
- A `LocationSource` abstraction (so widget tests can inject a fake; real geolocator hits platform channels unavailable in `flutter test`).
- A small **local** seed-pin model + 4–6 example pins (const Dart list — no backend, no network for the pins themselves).
- Runtime location-permission request, denied / forever-denied / service-disabled fallbacks, and an offline-tiles hint.
- New dependencies, Android manifest permissions, iOS Info.plist note, gradle note.
- New l10n keys filled in **en / zh / ms** (i18n is currently UNFROZEN for this feature — see Memory note; this spec adds keys deliberately).
- One widget test (fake-injected) proving the screen renders and never crashes for both "located" and "denied/null" cases.

### Out of scope (YAGNI)

- Offline / cached map tiles (`flutter_map_tile_caching`), turn-by-turn routing, geofencing, clustering, search-on-map, custom map styles.
- Backend-served pins, pin CRUD, syncing visited pins to the profile/XP system.
- google_maps_flutter (rejected — see §3.2).
- Background location, location history, "track me along a path".
- Any change to existing screens beyond adding the one Discover entry card and the one route.

---

## 3. Library decision

### 3.1 Chosen stack

| Package | Role | Notes |
|---|---|---|
| `flutter_map` | Renders the map widget + OSM raster tiles, marker layers, attribution | No API key, no billing |
| `latlong2` | `LatLng` value type used by flutter_map markers/center | Peer of flutter_map |
| `geolocator` | Runtime permission request + current GPS position | Wrapped behind `LocationSource` |

> **Version policy:** pin the **latest compatible** versions at implement time (run `flutter pub add flutter_map latlong2 geolocator` and let pub resolve against the current Flutter SDK `^3.11.4`). Do **not** hard-code version numbers from this document — they may be stale. After adding, `flutter pub get` and `flutter analyze` must pass.

### 3.2 Rejected alternative — `google_maps_flutter`

Rejected because it requires:

- A **Google Cloud API key** + an enabled billing account (Maps SDK for Android/iOS),
- Android gradle + `AndroidManifest` `<meta-data>` API-key wiring, and `Info.plist` key on iOS,
- A platform-native map view (heavier; harder to widget-test).

For a graded coursework feature that must "just work" in a screenshot with zero billing setup, **flutter_map + OpenStreetMap wins**: the rubric explicitly endorses OpenStreetMap, there is no key/billing, and the whole thing is pure-Dart widgets that degrade gracefully and are testable via an injected fake.

---

## 4. Dependencies & platform configuration

### 4.1 `pubspec.yaml`

Add under `dependencies:` (alongside the existing `dio`, `go_router`, `flutter_riverpod`, etc.):

```yaml
  flutter_map: ^<latest compatible at implement time>
  latlong2: ^<latest compatible at implement time>
  geolocator: ^<latest compatible at implement time>
```

No new assets are required (pins are a const Dart list — see §6.2). If the team later prefers a JSON asset for pins, register it under `flutter: assets:` — **out of scope for v1**.

### 4.2 Android — `android/app/src/main/AndroidManifest.xml`

The manifest currently declares only `INTERNET` and `POST_NOTIFICATIONS`. Add, as siblings of the existing `<uses-permission>` lines (before `<application>`):

```xml
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

`INTERNET` is already present (needed for OSM tile fetches) — no change there. geolocator performs the runtime permission request itself; no extra code in `MainActivity`.

### 4.3 Android — gradle

geolocator requires a reasonably recent `minSdkVersion` (commonly 21+) and `compileSdk`. The Flutter default in this project already satisfies this; **verify** `android/app/build.gradle(.kts)` `minSdk`/`compileSdk` at implement time and bump only if `flutter build apk --release` fails. Do not speculatively edit gradle.

### 4.4 iOS (Android-first project — documented for completeness)

The app is Android-first, but if/when iOS is built, add to `ios/Runner/Info.plist`:

```xml
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>LinguaQuest uses your location to show nearby learning scenarios on the map.</string>
```

No iOS API key is needed (OSM tiles, not Google).

---

## 5. Navigation wiring

### 5.1 Discover entry card

In `lib/features/discover/discover_screen.dart`, add one more `CompactEntryCard` to the existing `ListView` (consistent with the XP-tasks / lucky-draw / community rows). Suggested placement: after the community row.

```text
CompactEntryCard(
  icon:  <a map/place icon from AppIcons, e.g. AppIcons.map / AppIcons.place>,
  title: l10n.exploreMapTitle,
  color: AppTokens.primary (or an existing soft accent),
  onTap: () => context.push('/discover/map'),
)
```

> Confirm the exact icon constant exists in `core/theme/app_icons.dart`; if not, add a `map`/`place` indirection there following the existing AppIcons pattern (Material Symbols Rounded — per Memory "App icon system").

### 5.2 GoRoute

In `lib/core/routing/app_router.dart`:

1. Add the import: `import '../../features/discover/explore_map_screen.dart';`
2. Register a top-level route next to the other `/discover/...` routes (lines ~221–232):

```text
GoRoute(
  path: '/discover/map',
  builder: (context, state) => const ExploreMapScreen(),
),
```

`_tabIndexForPath` already maps any `/discover…` path to tab index 3, so the bottom nav highlight is correct with no change. The screen pushes as a top-level route (full screen, with its own AppBar back button), matching how the other Discover sub-screens behave.

---

## 6. Screen design — `ExploreMapScreen`

File: `lib/features/explore/explore_map_screen.dart` (new `features/explore/` folder) — or `features/discover/` if the team prefers to keep it beside the other Discover sub-screens. Pick one at implement time; the route import must match.

### 6.1 Widget structure

```
Scaffold
 ├─ AppBar
 │   ├─ leading: FallbackBackButton(fallbackLocation: '/discover')
 │   └─ title: Text(l10n.exploreMapTitle)
 ├─ body: Stack
 │   ├─ FlutterMap
 │   │   ├─ MapOptions(initialCenter: <current or default>, initialZoom: ~13)
 │   │   ├─ TileLayer(
 │   │   │     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
 │   │   │     userAgentPackageName: 'com.example.linguaquest' (real applicationId),
 │   │   │   )
 │   │   ├─ MarkerLayer( seed-pin markers — tap → _openPinSheet(pin) )
 │   │   ├─ MarkerLayer( current-location marker — only when a real position exists )
 │   │   └─ RichAttributionWidget( '© OpenStreetMap contributors' → openstreetmap.org/copyright )
 │   ├─ (top) Animated/optional banner: location-denied OR offline hint  (AppPill / AppCard)
 │   └─ (bottom-right) FloatingActionButton  → recenter on user (or request permission if not yet granted)
 └─ (no bottom nav here — full-screen sub-route)
```

Implementation notes:

- Use a `MapController` so the recenter FAB and "on first fix, animate to me" can call `mapController.move(latLng, zoom)`.
- The screen is a `StatefulWidget` (or a small Riverpod `ConsumerStatefulWidget`) holding: `LatLng? _userLatLng`, a `_LocationStatus` enum (`unknown / granted / denied / deniedForever / serviceDisabled`), and the const pin list.
- On `initState`, kick off `LocationSource.current()`; update state when it resolves. **Never** block the first frame on it — the map and pins render immediately at the default center, then recenter if/when a fix arrives.

### 6.2 Seed pin model + example pins

A tiny immutable model (new file, e.g. `lib/features/explore/scenario_pin.dart`):

```text
class ScenarioPin {
  final String id;           // stable key
  final double lat;
  final double lng;
  final String titleKey;     // l10n key name -> resolved at build via a small switch, see §8
  final String? lessonId;    // optional: deep-link into an existing Lesson/vocab
  final List<String> sampleWords; // optional themed words shown if no lessonId
}
```

Keep pins as a **small local `const` list** (`scenarioPins`) so they render with **no backend and no network** (network is only needed for the tile imagery). Example set — *Chinese-travel-scenario* theme around Beijing (real-ish coordinates; final concept/coords flagged in §11):

| id | title (en) | lat | lng | links to |
|---|---|---|---|---|
| `airport`    | Airport (机场)     | 40.0799 | 116.6031 | lesson `travel-airport` or sample words 机场/登机/护照 |
| `restaurant` | Restaurant (餐厅)  | 39.9085 | 116.3975 | lesson `travel-restaurant` or 菜单/点菜/买单 |
| `hotel`      | Hotel (酒店)       | 39.9163 | 116.3972 | lesson `travel-hotel` or 房间/前台/退房 |
| `station`    | Train Station (火车站) | 39.9027 | 116.4279 | lesson `travel-station` or 车票/站台/出发 |
| `market`     | Market (市场)      | 39.9230 | 116.3884 | sample words 蔬菜/水果/多少钱 |
| `park`       | Park (公园)        | 39.9319 | 116.4074 | sample words 散步/树/湖 |

> The `lessonId`s above are **illustrative** — at implement time, point each pin at an existing lesson id if one matches, otherwise leave `lessonId` null and rely on `sampleWords`. Do not invent lesson ids that don't exist; the CTA must degrade to "show themed words" when there's no matching lesson.

### 6.3 Pin bottom sheet

On marker tap, `showModalBottomSheet` presenting an `AppCard`-styled sheet:

- **Header:** pin title (localized) + a small `MascotImage` or place icon.
- **Body:** the themed words (`sampleWords`) as a compact list, OR a one-line "learn this scenario" teaser.
- **CTA (`AppPrimaryButton`, label `l10n.exploreMapPinCta`):**
  - If `pin.lessonId != null` and that lesson exists → `context.push('/lesson/<id>')`.
  - Else → either push the wordbook/search filtered to those words, or simply display the `sampleWords` inline (no navigation). Choose the simplest that compiles against current routes; `/lesson/:id` and `/wordbook` already exist (see app_router).
- **Secondary:** `AppSecondaryButton` "Close" (or rely on sheet drag-dismiss).

Use existing Cozy Quest primitives (`AppCard`, `AppPrimaryButton`/`AppSecondaryButton`, `AppPill`, `SectionHeader`) for all non-map chrome so the screen matches the design system. The map itself is third-party and keeps flutter_map's native look.

### 6.4 Recenter FAB

- `FloatingActionButton` (bottom-right) with a "my location" icon.
- If location already granted and `_userLatLng != null` → `mapController.move(_userLatLng!, 15)`.
- If permission not yet granted/denied → re-invoke `LocationSource.current()` (which re-requests); on success, drop the marker + recenter; on denial, surface the denied banner (§7).

---

## 7. Permission / offline / error flows

All flows must **never crash** and must always leave a usable map (pins visible).

### 7.1 Location permission

`LocationSource` (real impl, §8) does, in order:

1. Check location services enabled → if not, status = `serviceDisabled`, return `null`.
2. Check permission; if `denied`, request it.
3. If `deniedForever` or `denied` after request → status = `denied`, return `null`.
4. If `granted` → return `Geolocator.getCurrentPosition()` as `LatLng`.

### 7.2 Denied / null → default center + banner

When `current()` returns `null` (any reason): center the map on a **fixed default coordinate** (e.g. Beijing `39.9087, 116.3975`, matching the pin cluster so pins are on-screen), draw **no** current-location marker, and show a dismissible banner/pill (`l10n.exploreMapLocationDenied`) explaining location is off. The recenter FAB then acts as "try again / grant".

### 7.3 Offline tiles

OSM tiles require network. flutter_map renders blank/grey tiles when offline rather than crashing. Add a subtle, non-blocking hint (`l10n.exploreMapOfflineHint`, e.g. "Offline — map tiles may not load") shown when a tile error/`evictErrorTileStrategy` fires or simply as a static footer note. **Pins still render** over blank tiles, so the feature still "displays locations" offline. Do not gate the screen on connectivity.

### 7.4 Crash-safety summary

| Condition | Behaviour |
|---|---|
| GPS granted + fix | Current-location marker + pins, recenter works |
| GPS denied / forever | Default center + denied banner + pins; no current marker |
| Location services off | Same as denied (serviceDisabled banner copy or shared denied copy) |
| No network | Blank tiles + offline hint + pins still drawn |
| `flutter test` (no platform channels) | Fake `LocationSource` injected — see §10 |

---

## 8. `LocationSource` abstraction (testability seam)

A tiny interface so the screen never calls geolocator directly:

```text
abstract class LocationSource {
  Future<LatLng?> current();      // null = unavailable/denied
  // optional: Future<LocationStatus> status();  if the banner needs the reason
}

class GeolocatorLocationSource implements LocationSource { ... real plugin ... }
class FakeLocationSource implements LocationSource {
  FakeLocationSource(this._value);
  final LatLng? _value;
  @override Future<LatLng?> current() async => _value;
}
```

Wiring: `ExploreMapScreen` takes an optional `LocationSource? locationSource` constructor param defaulting to `GeolocatorLocationSource()` (or a Riverpod `locationSourceProvider` that tests can `overrideWith`). The route builder uses the default; tests inject `FakeLocationSource`.

> Returning a richer status enum (denied vs serviceDisabled) is optional polish; v1 can map "null → denied banner" and keep one banner string. Keep it minimal.

---

## 9. Attribution (OSM licence requirement)

OpenStreetMap's tile usage policy **requires** visible attribution. Use flutter_map's `RichAttributionWidget` with a `TextSourceAttribution('© OpenStreetMap contributors', onTap: launch openstreetmap.org/copyright)`. This is non-negotiable and also looks good in the graded screenshot. Set a real `userAgentPackageName` on the `TileLayer` (OSM tile policy expects a meaningful UA).

---

## 10. Testing approach

### 10.1 Widget test (the CI-safe proof)

New file `test/features/explore/explore_map_screen_test.dart`. Real geolocator hits platform channels that don't exist under `flutter test`; the `LocationSource` seam makes this testable.

Two cases, both pumping `ExploreMapScreen` inside a minimal `MaterialApp` with `AppLocalizations` delegates (and a `MapController`/network-image-safe harness — flutter_map tile HTTP is mocked/no-op in tests; assert on widgets, not tiles):

1. **Located:** inject `FakeLocationSource(LatLng(39.9087, 116.3975))`. Pump-and-settle. Assert: the screen builds without throwing, the `FlutterMap` is present, the seed pins' `MarkerLayer` is present (assert pin count / a known pin's semantics/key), and a current-location marker exists.
2. **Denied / null:** inject `FakeLocationSource(null)`. Pump-and-settle. Assert: **no exception**, `FlutterMap` + pins still present, the denied banner text (`l10n.exploreMapLocationDenied`) is found, and **no** current-location marker.

The key assertions: *pins render in both cases* and *no crash when location is null*. This keeps the graded feature green in CI without a device.

> Tile HTTP in tests: wrap the pump in flutter's default test HTTP override (returns transparent images) or assert only on non-tile widgets. Avoid real network in tests.

### 10.2 Static + suite

- `flutter analyze` — must pass (no new lints; `flutter_lints` via `analysis_options.yaml`).
- `flutter test` — full suite green, including the new test and the existing `app_tokens_test.dart`/widget tests.
- `flutter gen-l10n` after editing `.arb` files, and commit the regenerated `lib/l10n/generated/` (it is committed in this repo).

### 10.3 Manual / screenshot verification (for the report)

`flutter run` on an emulator/device, open Discover → "Explore Map", grant location, confirm: tiles load, current-location marker appears, pins tappable, bottom sheet + CTA work, attribution visible. Capture the screenshot. Then deny location and confirm the banner + pins still render.

---

## 11. l10n keys to add (en / zh / ms)

i18n is UNFROZEN for this feature. Add the following keys to `app_en.arb` (template), `app_zh.arb`, `app_ms.arb`, then run `flutter gen-l10n`. Follow existing ARB conventions (the file uses plain `"key": "value"` entries; add `@key` description metadata to match neighbouring entries if the team does so).

| Key | en | zh | ms |
|---|---|---|---|
| `exploreMapTitle` | Explore Map | 探索地图 | Peta Jelajah |
| `exploreMapSubtitle` | Discover learning scenarios near you | 发现你附近的学习场景 | Temui senario pembelajaran berhampiran anda |
| `exploreMapRecenter` | Recenter on me | 回到我的位置 | Pusatkan pada saya |
| `exploreMapLocationDenied` | Location is off — showing the default area. Tap the locate button to enable. | 定位已关闭——正在显示默认区域。点击定位按钮以开启。 | Lokasi dimatikan — memaparkan kawasan lalai. Ketik butang lokasi untuk hidupkan. |
| `exploreMapOfflineHint` | Offline — map tiles may not load | 离线——地图瓦片可能无法加载 | Luar talian — jubin peta mungkin tidak dimuatkan |
| `exploreMapPinCta` | Start this scenario | 开始这个场景 | Mulakan senario ini |
| `exploreMapClose` | Close | 关闭 | Tutup |
| `exploreMapAttribution` | © OpenStreetMap contributors | © OpenStreetMap 贡献者 | © Penyumbang OpenStreetMap |
| `exploreMapPinAirport` | Airport | 机场 | Lapangan Terbang |
| `exploreMapPinRestaurant` | Restaurant | 餐厅 | Restoran |
| `exploreMapPinHotel` | Hotel | 酒店 | Hotel |
| `exploreMapPinStation` | Train Station | 火车站 | Stesen Kereta Api |
| `exploreMapPinMarket` | Market | 市场 | Pasar |
| `exploreMapPinPark` | Park | 公园 | Taman |

Resolve each `ScenarioPin.titleKey` to its localized string in the screen build via a small `switch` on the pin id (avoid dynamic key lookup — `AppLocalizations` is codegen'd, not map-indexed).

---

## 12. Open decisions (flag for user)

1. **Pin concept & coordinates (final):** This spec proposes *Chinese-travel-scenarios around Beijing* (Airport/Restaurant/Hotel/Station/Market/Park). Alternative: *Chinese-culture POIs* (Great Wall, Forbidden City, etc.) as pure "display location" pins. **Pick one + confirm the 4–6 coordinates.**
2. **Pin → content link:** Should each pin deep-link into a real existing `Lesson` (requires matching lesson ids in the seed data), or just show `sampleWords` inline? Default = link if a lesson exists, else inline words.
3. **Default center:** Confirm the fallback coordinate (proposed Beijing `39.9087, 116.3975`) — it should keep the pins on-screen when GPS is denied.
4. **Screen folder:** `features/explore/` (new) vs `features/discover/` (beside siblings). Route import must match the choice.
5. **Connectivity detection for the offline hint:** static footer note (simplest) vs reacting to tile-load errors. Default = static note unless the tile error hook is trivial.

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Map tiles need network | Blank tiles offline; bad screenshot | Offline hint; pins render over blank tiles; capture report screenshot online |
| geolocator can't run in `flutter test` (platform channels) | Feature untestable in CI | `LocationSource` seam + `FakeLocationSource` injection (§8, §10) |
| OSM tile policy / attribution | Licence violation / tiles throttled | RichAttributionWidget "© OpenStreetMap contributors" + real `userAgentPackageName` (§9) |
| Permission denied / services off | Crash or empty screen | Default center + banner + pins; never block on location (§7) |
| Dependency version drift vs Flutter `^3.11.4` | `pub get` fails | Add via `flutter pub add` and pin latest compatible at implement time (§4.1) |
| google_maps path creep | Wasted setup, billing | Explicitly rejected (§3.2); flutter_map is the decision |
| New ARB keys vs prior "translation freeze" memory | Inconsistent i18n | i18n explicitly UNFROZEN for this feature; en/zh/ms all provided (§11) |

---

## 14. Definition of done

- [ ] `flutter_map`, `latlong2`, `geolocator` added; `flutter pub get` clean.
- [ ] `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` in AndroidManifest; iOS Info.plist note recorded.
- [ ] `/discover/map` route + Discover entry card wired; bottom nav still highlights Discover.
- [ ] `ExploreMapScreen` renders OSM tiles, current-location marker (when granted), 4–6 pins, recenter FAB, pin bottom sheet with CTA, and OSM attribution.
- [ ] Denied/null and offline paths handled with no crash; pins always visible.
- [ ] `LocationSource` + `FakeLocationSource`; widget test covers located + denied cases.
- [ ] l10n keys added in en/zh/ms; `flutter gen-l10n` run and generated code committed.
- [ ] `flutter analyze` clean; `flutter test` green.
- [ ] Report screenshot of the working map captured.
```