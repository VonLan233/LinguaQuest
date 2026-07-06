# Design Spec — Issue #77 Maps (§1.1 Language-Selection Map + §1.2 About Company Map)

- **Date:** 2026-06-26
- **Issue:** GitHub #77 §1.1, §1.2
- **Course context:** SWE311 coursework. **Map is a graded feature.** This spec adds two new map surfaces that exercise the mapping API (`flutter_map`) and demonstrate two distinct map use-cases (interactive selection + read-only locator).
- **Status:** Design only. No Dart in this document; implementation follows in a separate plan.

---

## 1. Overview

The app already ships one map screen — `lib/features/map/study_map_screen.dart` — which uses `flutter_map ^7.0.2` + `latlong2 ^0.9.1` + `geolocator ^13.0.1` over OpenStreetMap tiles. This spec reuses that exact, proven `FlutterMap` pattern to add two more graded map deliverables:

- **§1.1 Language-Selection Map** — a new full-screen world map (`/language-map`) where country markers represent learnable languages. Tapping the enabled China marker drives a real language-selection flow (`updateTargetLanguage('zh')`); coming-soon markers show a localized snackbar. This demonstrates an **interactive map + map-driven app action**.
- **§1.2 About Company Map** — a read-only company-location card embedded in the existing `/about` screen (`lib/features/profile/about_screen.dart`). A fixed-center map with a single marker for the (virtual) company HQ. This demonstrates a **static map locator with attribution**.

### How this maps to the issue and strengthens the graded Map feature

| Issue clause | Deliverable | Map capability demonstrated |
|---|---|---|
| §1.1 Language-selection map | New `LanguageMapScreen` at `/language-map` | World-scale interactive map, multiple markers keyed by language, marker tap → bottom sheet → state mutation, marker tap → snackbar |
| §1.2 About company map | Map card added to `AboutScreen` | Fixed-center read-only map, single marker, `RichAttributionWidget` OSM attribution |

Together with the pre-existing Study Map (GPS + add-spot), the app now shows **three** clearly differentiated map use-cases, which is what the graded Map rubric rewards: live geolocation (existing), interactive selection (§1.1), and static locator (§1.2).

---

## 2. Scope

### In scope
- New screen `lib/features/map/language_map_screen.dart` + route `/language-map`.
- Drawer entry "Choose Language" → `/language-map` in `lib/features/shell/app_drawer.dart`.
- Edit `lib/features/profile/about_screen.dart` to add a company-map `AppCard`.
- New l10n keys in `app_en.arb` / `app_zh.arb` / `app_ms.arb` (i18n is **unfrozen** for this work) + regenerated `lib/l10n/generated/`.
- Two widget tests (no GPS, no live network assertions).

### Out of scope (YAGNI)
- No change to the actual learning content or locale lock — the app stays **English-UI / Chinese-target (`zh`)**. §1.1 is a *simulated* selection flow that still calls the real `updateTargetLanguage`.
- No new language data, no unlocking of coming-soon languages.
- No GPS / geolocation on either new map (only the existing Study Map uses `geolocator`).
- No backend changes.
- No recenter button / no "my location" on either new map.

---

## 3. Reused building blocks (grounded in real code)

### 3.1 The flutter_map pattern (from `study_map_screen.dart`)
The working pattern to copy (`study_map_screen.dart:127-154`):

```
FlutterMap(
  options: MapOptions(initialCenter: <LatLng>, initialZoom: <n>, ...),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.linguaquest',
    ),
    MarkerLayer(markers: [ Marker(point: <LatLng>, width:, height:, child: <Widget>) ]),
  ],
)
```
- `import 'package:flutter_map/flutter_map.dart';` and `import 'package:latlong2/latlong.dart';` (`LatLng`).
- Markers carry a tappable `child` (wrap the icon in `GestureDetector`/`InkWell`) — the existing screen's markers are non-interactive, so §1.1 adds the tap handling on the marker `child`.
- `RichAttributionWidget` is **not** present in the existing screen; §1.2 adds it explicitly (issue requires "© OpenStreetMap contributors").

### 3.2 Language list (from `target_language_picker.dart:11-18`)
Reuse the existing constants verbatim — do **not** redefine the language set:
- `kActiveTargetLanguages = {'zh': 'Chinese (中文)'}` → the single enabled marker.
- `kComingSoonTargetLanguages = {'ms': 'Malay (Bahasa Melayu)', 'es': 'Spanish (Español)', 'fr': 'French (Français)', 'ja': 'Japanese (日本語)'}` → the coming-soon markers.
- `targetLanguageLabel(code)` for display labels.

A new private const map in `language_map_screen.dart` provides coordinates per code (kept local since it's pure presentation):

| code | language | country | LatLng | enabled |
|---|---|---|---|---|
| `zh` | Chinese (中文) | China (Beijing) | `LatLng(39.9087, 116.3975)` | ✅ active |
| `en` | English | United States | `LatLng(38.0, -97.0)` | coming soon* |
| `es` | Spanish (Español) | Spain | `LatLng(40.4, -3.7)` | coming soon |
| `fr` | French (Français) | France | `LatLng(46.6, 2.3)` | coming soon |
| `ja` | Japanese (日本語) | Japan | `LatLng(36.2, 138.2)` | coming soon |
| `ms` | Malay (Bahasa Melayu) | Malaysia | `LatLng(4.2, 101.9)` | coming soon |

\* `en` is not in `kComingSoonTargetLanguages` (the UI locale, not a study target). It is included as a coming-soon **pin** for map richness; its label can be a literal `"English"` or a new l10n key (see Open Decisions). All non-`zh` pins behave identically (snackbar only).

### 3.3 State mutation (from `app_controller.dart:335-339`, `app_state.dart:130/174`)
- `ref.read(appControllerProvider.notifier).updateTargetLanguage(code)` — sets `state.targetLanguage` and persists to `SharedPreferences` (key `_targetLanguageKey`). It is `async`; await it before showing the confirmation snackbar.
- `AppState.targetLanguage` defaults to `'zh'`.

### 3.4 Cozy Quest primitives
- `AppCard` (`app_card.dart`) — wraps the bottom-sheet content and the company-map card. Signature: `AppCard({required child, padding, onTap})`.
- `AppPrimaryButton` (`app_button.dart:7`) — `AppPrimaryButton({required label, required onPressed, icon})` for the bottom-sheet confirm.
- `AppPill` with `PillVariant.neutral` — "Coming Soon" badge on coming-soon pins/sheet (matches the picker convention at `target_language_picker.dart:59`).
- `FallbackBackButton` (`fallback_back_button.dart:5`) — `FallbackBackButton({required fallbackLocation})` for the language-map AppBar leading (fallback `/home`).
- `AppTokens.*` for spacing/radii/colors. About screen already uses `AppTokens.s16/s20/radiusCard`.

---

## 4. §1.1 — LanguageMapScreen widget structure

**File (new):** `lib/features/map/language_map_screen.dart`
**Route (new):** `/language-map`
**Type:** `ConsumerStatefulWidget` (needs `ref` for `updateTargetLanguage`; `ConsumerWidget` is acceptable too — no per-frame load needed, unlike Study Map). A `MapController` is optional (no programmatic `move`); include only if a future recenter is wanted — omit for YAGNI.

```
Scaffold
 ├─ appBar: AppBar(
 │     leading: FallbackBackButton(fallbackLocation: '/home'),
 │     title: Text(l10n.languageMapTitle))
 └─ body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(20, 80),   // world-ish center
          initialZoom: 2.2,                 // ~world (issue: 2-3)
          minZoom: 1, maxZoom: 6,           // keep it a "world picker"
          interactionOptions: drag + pinch-zoom enabled (default)),
        children: [
          TileLayer(urlTemplate: OSM, userAgentPackageName: 'com.example.linguaquest'),
          MarkerLayer(markers: [
            for each language pin →
              Marker(
                key: ValueKey('lang-pin-<code>'),   // REQUIRED for tests
                point: <LatLng>, width: 44, height: 44,
                child: GestureDetector(
                  onTap: () => _onPinTap(code, enabled),
                  child: Icon(place/flag, color: enabled ? primary : muted))),
          ]),
          RichAttributionWidget(attributions: [ '© OpenStreetMap contributors' ]),
        ])
```

### 4.1 Tap flows

**China (`zh`, enabled) → bottom sheet → confirm:**
```
_onPinTap('zh', enabled: true):
  showModalBottomSheet(
    context, builder: AppCard(
      child: Column [
        Text(l10n.languageMapSelectPrompt),                 // "Select a language to learn"
        Text(targetLanguageLabel('zh')) // "Chinese (中文)"  (or l10n.languageMapChinese)
        AppPrimaryButton(
          key: ValueKey('lang-confirm-zh'),
          label: l10n.languageMapConfirm('Chinese (中文)'),  // "Learn Chinese (中文)"
          onPressed: () async {
            await ref.read(appControllerProvider.notifier).updateTargetLanguage('zh');
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.languageMapSelected('Chinese (中文)'))));
          }),
      ]))
```
Because the app is hard-locked to `zh`, this re-confirms `zh` — but it calls the **real** method so the flow (and its persistence side-effect) is genuine and testable.

**Coming-soon pin (any non-`zh`) → snackbar, no state change:**
```
_onPinTap(code, enabled: false):
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.languageMapComingSoon(<language label>))));
```

### 4.2 Keys for testability
- Markers: `ValueKey('lang-pin-zh')`, `'lang-pin-en'`, `'lang-pin-es'`, `'lang-pin-fr'`, `'lang-pin-ja'`, `'lang-pin-ms'`.
- Confirm button: `ValueKey('lang-confirm-zh')`.

---

## 5. §1.2 — About company map (edit AboutScreen)

**File (modified):** `lib/features/profile/about_screen.dart`

Insert one more `AppCard` into the existing `ListView` (after the info-cards `AppCard`, `about_screen.dart:124`). The screen is a `StatelessWidget` — no state needed.

```
AppCard(
  padding: EdgeInsets.zero,
  child: Column [
    Padding(s16) → Column(crossAxis.start) [
      Text(l10n.aboutCompanyName)                 // "LinguaQuest"
      Text(l10n.aboutCompanyAddress)              // virtual address (see below)
      Text(l10n.aboutCompanyDescription) ]        // 1-line blurb
    ClipRRect(bottom corners radiusCard) → SizedBox(
      height: 200,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(2.8316, 101.7070),  // virtual HQ near XMUM, Sepang
          initialZoom: 14,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.none)), // read-only — see decision
        children: [
          TileLayer(urlTemplate: OSM, userAgentPackageName: 'com.example.linguaquest'),
          MarkerLayer(markers: [
            Marker(key: ValueKey('company-pin'),
                   point: LatLng(2.8316, 101.7070), width: 40, height: 40,
                   child: Icon(place, color: coral/primary)) ]),
          RichAttributionWidget(attributions: [ '© OpenStreetMap contributors' ]),  // REQUIRED
        ])),
  ])
```

- **Read-only decision:** disable interaction (`InteractiveFlag.none`) so the card is a pure locator and never steals scroll gestures from the surrounding `ListView`. (Alternative: leave pan/zoom default-enabled — noted as an open decision; default-disabled is the recommendation.)
- **Company identity (virtual):**
  - Name: `LinguaQuest`
  - Virtual address: *"Block A, LinguaQuest HQ (virtual), Xiamen University Malaysia, Jalan Sunsuria, Bandar Sunsuria, 43900 Sepang, Selangor, Malaysia"* — held as an l10n string (`aboutCompanyAddress`).
  - Coords: `LatLng(2.8316, 101.7070)` (near XMUM, Sepang).
  - Description: short blurb, e.g. *"Our virtual campus where LinguaQuest is built."*

---

## 6. Navigation wiring

### 6.1 Drawer (`app_drawer.dart`)
Add one item (the `item(icon, label, route)` helper at `app_drawer.dart:11`). Insert after the existing map items (after line 33):
```
item(AppIcons.language /* or .translate */, l10n.drawerChooseLanguage, '/language-map'),
```
Note: the drawer currently uses **hard-coded English** labels (`'Study Map'`, etc.) and has no `l10n` in scope. Two options: (a) match existing style with a literal `'Choose Language'`; (b) introduce `AppLocalizations.of(context)` and a key. **Recommendation:** literal string to match the file's current convention, with the l10n key reserved for the screen itself. (Open decision.)

### 6.2 Route (`app_router.dart`)
- Add import: `import '../../features/map/language_map_screen.dart';` (near line 55-56).
- Register a top-level `GoRoute` next to `/map` (line 219):
```
GoRoute(path: '/language-map', builder: (context, state) => const LanguageMapScreen()),
```
`/language-map` is **not** inside the `ShellRoute` (no bottom tab) and won't match `_tabIndexForPath` — it renders full-screen with its own AppBar, consistent with `/map`.

### 6.3 Optional second entry point (note only)
Settings (`/settings`) could also link to `/language-map` (it already hosts the target-language picker via `showTargetLanguageSheet`). Out of scope for this pass; noted as an optional follow-up entry point.

### 6.4 About screen — no nav change
`/about` already exists (`app_router.dart:218`, drawer line 38). Only the screen body changes.

---

## 7. l10n keys to add (en / zh / ms)

i18n is **unfrozen** for this work. Add to `app_en.arb` (template), then `app_zh.arb`, `app_ms.arb`, then run `flutter gen-l10n` and commit `lib/l10n/generated/`. Placeholder syntax follows the ARB format already in the file.

| Key | en | zh | ms |
|---|---|---|---|
| `languageMapTitle` | Choose Language | 选择学习语言 | Pilih Bahasa |
| `languageMapSelectPrompt` | Tap a country to choose the language you want to learn. | 点击国家选择你想学习的语言。 | Ketik sebuah negara untuk memilih bahasa yang ingin dipelajari. |
| `languageMapChinese` | Chinese (中文) | 中文 | Bahasa Cina (中文) |
| `languageMapConfirm` | Learn {language} | 学习{language} | Belajar {language} |
| `languageMapSelected` | Now learning {language} | 已切换到{language} | Kini belajar {language} |
| `languageMapComingSoon` | {language} — coming soon | {language}：暂未开放 | {language} — akan datang |
| `drawerChooseLanguage` | Choose Language | 选择语言 | Pilih Bahasa |
| `aboutCompanyName` | LinguaQuest | LinguaQuest | LinguaQuest |
| `aboutCompanyAddress` | Xiamen University Malaysia, Bandar Sunsuria, 43900 Sepang, Selangor, Malaysia (virtual) | 厦门大学马来西亚分校，雪兰莪州雪邦 43900（虚拟地址） | Universiti Xiamen Malaysia, Bandar Sunsuria, 43900 Sepang, Selangor, Malaysia (maya) |
| `aboutCompanyDescription` | Our virtual campus where LinguaQuest is built. | 我们打造 LinguaQuest 的虚拟园区。 | Kampus maya tempat LinguaQuest dibina. |

Placeholders: `languageMapConfirm`, `languageMapSelected`, `languageMapComingSoon` each declare a `{language}` String placeholder in their `@`-metadata block (mirror an existing parameterized key's metadata format).

> `drawerChooseLanguage` is listed for completeness; only needed if the drawer is localized (see §6.1 — recommendation is a literal, so this key may be skipped).

---

## 8. Files created / modified

**Created**
- `lib/features/map/language_map_screen.dart` — §1.1 screen.
- `test/features/map/language_map_screen_test.dart` — §1.1 widget test.
- `test/features/profile/about_screen_map_test.dart` — §1.2 widget test (or add a case to an existing about test if one exists).

**Modified**
- `lib/core/routing/app_router.dart` — import + `/language-map` route.
- `lib/features/shell/app_drawer.dart` — "Choose Language" drawer item.
- `lib/features/profile/about_screen.dart` — company-map `AppCard`.
- `lib/l10n/app_en.arb`, `app_zh.arb`, `app_ms.arb` — new keys.
- `lib/l10n/generated/*` — regenerated by `flutter gen-l10n` (committed).

---

## 9. Testing approach

Both tests run under `flutter test` with **no GPS and no live network**. `TileLayer` issues HTTP tile requests; in the widget-test environment these resolve to no-op/empty images and never block `pumpAndSettle` indefinitely because we **assert on widgets/keys, never on rendered tiles**. (If flakiness appears, wrap with `mockNetworkImagesFor` from `network_image_mock`, or pump with a fixed duration instead of `pumpAndSettle` — note, not required for the assertions below.)

### 9.1 §1.1 test — `language_map_screen_test.dart`
Pump `LanguageMapScreen` inside `ProviderScope` (with `AppLocalizations` delegates + `MaterialApp`). Strategy for verifying the state call without a backend:
- **Option A (state assertion):** read `appControllerProvider`'s `targetLanguage` before/after; tap `find.byKey(ValueKey('lang-pin-zh'))`, then `find.byKey(ValueKey('lang-confirm-zh'))`, `await tester.pumpAndSettle()`, assert state `targetLanguage == 'zh'`. (Mock repos run fully offline — `updateTargetLanguage` only touches state + `SharedPreferences`, which `SharedPreferences.setMockInitialValues({})` makes test-safe.)
- **Option B (spy override):** override `appControllerProvider` with a fake notifier that records `updateTargetLanguage` calls; assert it was invoked with `'zh'`.
- **Recommendation:** Option A — simplest, exercises the real notifier. Add `SharedPreferences.setMockInitialValues({})` in `setUp`.
- **Coming-soon assertion:** tap `find.byKey(ValueKey('lang-pin-ja'))`, `pump()`, assert a `SnackBar` containing the coming-soon text is present and `targetLanguage` is unchanged.
- Tiles/markers: assert `find.byType(FlutterMap)` and the six pin keys all `findsOneWidget`.

### 9.2 §1.2 test — `about_screen_map_test.dart`
Pump `AboutScreen` (needs `MaterialApp` + `AppLocalizations` delegates; it's a plain `StatelessWidget`, no `ProviderScope` strictly required, but include one for safety). Assert:
- `find.byType(FlutterMap)` `findsOneWidget` (the company map renders without crash).
- `find.byKey(ValueKey('company-pin'))` `findsOneWidget`.
- Text `find.text('LinguaQuest')` present (company name).
- No exception thrown during build/settle.

### 9.3 Gate
`flutter analyze` and `flutter test` must pass; run `flutter gen-l10n` first so generated localizations compile.

---

## 10. Open decisions

1. **Drawer label localization** — literal `'Choose Language'` (matches current hard-coded drawer style) vs. introduce `l10n` + `drawerChooseLanguage`. *Recommendation: literal.*
2. **Second entry point (Settings)** — add a `/language-map` link from Settings now, or defer. *Recommendation: defer (note only).*
3. **`en` pin** — include a US/English coming-soon pin (richer map) using a literal `"English"` label, or restrict pins to `kActiveTargetLanguages ∪ kComingSoonTargetLanguages` only. *Recommendation: include `en` with a literal label.*
4. **Company-map interactivity** — `InteractiveFlag.none` (read-only, won't fight ListView scroll) vs. default pan/zoom. *Recommendation: `none`.*
5. **Exact coords** — pin coordinates above are approximate "country centroids" / a virtual HQ point; confirm they look right on-device. Company coords `LatLng(2.8316, 101.7070)` ≈ XMUM Sepang.
6. **Address string** — kept as the l10n value `aboutCompanyAddress` (vs. a bare const). *Recommendation: l10n string (enables zh/ms).*
7. **Marker icon** — reuse `Icons.place` (as Study Map) vs. a flag/`AppIcons` glyph. *Recommendation: `Icons.place`, colored by enabled/disabled state.*

---

## 11. Risks & mitigations

- **Tile network in tests** — `TileLayer` fires HTTP. *Mitigation:* assertions target widgets/keys, not pixels; use `SharedPreferences.setMockInitialValues({})`; if `pumpAndSettle` hangs, switch to timed `pump()` or `network_image_mock`.
- **Marker tap not hit in test** — markers are small; *Mitigation:* `ValueKey`-based `find.byKey` + `tester.tap(..., warnIfMissed: false)` if needed.
- **Locale lock confusion** — §1.1 appears to "change language" but app stays `zh`. *Mitigation:* documented as a *simulated* flow that still calls the real, persisted `updateTargetLanguage('zh')`; coming-soon pins make the limitation explicit in-UI.
- **ListView gesture conflict on About map** — *Mitigation:* `InteractiveFlag.none` (decision 4).
- **i18n** — must run `flutter gen-l10n` and commit generated output, or build breaks (per CLAUDE.md).
```
