# Design Spec — Issue #77 §7 成就系统与抽奖 (Achievements & Lottery)

- Date: 2026-06-26
- Issue: #77 §7「成就系统与抽奖」
- Status: Draft (design only, no code)
- i18n: UNFROZEN — new ARB keys are allowed and required for this work.

## 1. Overview & mapping to §7

Issue #77 §7 asks for three additive improvements to the existing reward layer:

| §7 requirement | This spec delivers |
| --- | --- |
| 更多抽奖奖品 (more lottery prizes) | Expand `lotteryPrizeSeed` from 6 → 15 prizes across the existing 6 categories + comfort, probabilities re-summed to 100. |
| 更好的奖池 + 用户资产展示 (better prize-pool + user-asset display) | Redesign `lucky_draw_screen` prize list (group by category, show rarity) + new dedicated **Asset Inventory** screen at `/discover/assets`. |
| 更多学习成就 (more learning achievements) | Add 4 achievements (`learn_100_words`, `quiz_perfect`, `first_map_language`, `first_listening`), evaluated from existing DB stats plus 2 minimal new signals. |
| 重复奖品累计/碎片转化 (duplicate accumulation / fragment conversion) | Already implemented; **verify + document only** (see §7). |

This is strictly **additive**. No new systems, no new tables unless explicitly called out (none are required for the core scope; one optional column is the only DB change, for `first_map_language`).

### Grounding (verified path:line)

- `server/lib/src/lottery_policy.dart:5-60` — `lotteryPrizeSeed` (6 prizes), probabilities currently sum to 100; `chooseLotteryPrize` weights by `probability` (any total, not just 100).
- `server/lib/src/routes.dart:469-484` — `GET /lottery/prizes`, `GET /lottery/assets`; `routes.dart:486-513` — `POST /lottery/draw`.
- `server/lib/src/routes.dart:892-911` — `GET /achievements`: derives `streak`, `xp`, `masteredWords` (mastery_level ≥ 4), `totalStudyDays` (`completedLessonIds(uid).isNotEmpty ? 1 : 0`).
- `server/lib/src/achievement_policy.dart:39-97` — `AchievementPolicy.evaluate(streakDays, masteredWords, totalStudyDays, trainingXp)` returns 6 achievements.
- `server/lib/src/database.dart:392-407` — `user_assets` table, `UNIQUE (uid, prize_id)`; `database.dart:1517-1549` — draw insert with `ON CONFLICT (uid, prize_id) DO UPDATE SET quantity=user_assets.quantity + 1` (duplicate accumulation already correct).
- `server/lib/src/database.dart:243-256` — `exercise_records` (`game_id`, `prompt_type`, `is_correct`, `dimension`) — signal source for listening/perfect-quiz achievements.
- `linguaquest/lib/data/models/lottery.dart:1-150` — `LotteryPrize` / `UserAsset` (`isComfortReward`, `totalFragments`, `categoryLabelFor`).
- `linguaquest/lib/data/models/achievement.dart:39-99` — client `AchievementEvaluator.evaluate(...)` mirrors server.
- `linguaquest/lib/features/discover/lucky_draw_screen.dart:195-245` — `_ProbabilityList` (flat list, no grouping).
- `linguaquest/lib/features/quests/achievements_screen.dart` — achievements UI (hard-coded English titles "Achievements" / "Your Achievements").
- `linguaquest/lib/data/repositories/mock_repositories.dart:707-762` — `_mockPrizePool` (6 prizes; must mirror server); `mock_repositories.dart:1333-1342` — `MockLearningRepository.getAchievements`.
- `linguaquest/lib/core/routing/app_router.dart:231-238` — `/discover/lucky-draw` route registration pattern.
- `server/test/lottery_policy_test.dart` — asserts `probabilityTotal == 100` and category coverage (this test MUST be updated to the new total = 100 with new categories still present).

## 2. Scope

**In scope**
- Expand lottery prize seed (server) + mirror in Mock prize pool (app).
- Redesign lucky-draw prize-pool display (grouped, rarity-clear, Cozy Quest primitives).
- New Asset Inventory screen + route `/discover/assets` + entry points.
- 4 new achievements + their evaluation sources + 2 minimal new signals.
- i18n keys (en/zh/ms) for new prize names, achievement titles/descriptions, inventory UI, and the now-localized achievements screen chrome.
- Tests: server (prize sum, new achievement evaluation) + Flutter (inventory renders, expanded prizes shown).

**Out of scope**
- No prize that grants any learning/score boost (decorative-only invariant preserved — see `lottery_policy_test.dart` guards against `learningBoost`/`scoreBoost`).
- No fragment-redemption/spend flow (display `totalFragments` only; spending is a separate future feature).
- No equip/use of cosmetic assets (avatar frames etc. are owned & displayed, not yet applied to the avatar).
- No achievement reward payout (achievements stay badge-only, matching current behavior).
- No new lottery economy tuning beyond probability rebalancing to 100.

## 3. Expanded prize list (server `lotteryPrizeSeed`, mirrored in Mock `_mockPrizePool`)

15 prizes. `probability` values sum to **100.0**. Same `Prize` shape: `id, name, category, rarity, description, probability, fragmentValue`. `fragmentValue` scales with rarity (rare 16–20, uncommon 8–10, common 4–6, comfort 3). The single `fragment` (comfort) prize stays the safety-net pad.

| id | category | rarity | probability | fragmentValue |
| --- | --- | --- | ---: | ---: |
| `avatar-frame-starry` *(existing)* | avatarFrame | rare | 4.0 | 18 |
| `avatar-frame-ember` *(new)* | avatarFrame | rare | 3.0 | 18 |
| `profile-bg-aurora` *(existing)* | profileBackground | rare | 4.0 | 16 |
| `profile-bg-dawn-harbor` *(new)* | profileBackground | rare | 3.0 | 16 |
| `badge-focus-sprinter` *(existing)* | badge | uncommon | 9.0 | 8 |
| `badge-night-owl` *(new)* | badge | uncommon | 7.0 | 8 |
| `badge-anniversary-lantern` *(new, special-event)* | badge | rare | 2.0 | 20 |
| `title-arena-scout` *(existing)* | title | uncommon | 8.0 | 8 |
| `title-lexicon-keeper` *(new)* | title | uncommon | 7.0 | 8 |
| `title-dawn-voyager` *(new)* | title | rare | 3.0 | 16 |
| `card-skin-mint` *(existing)* | cardSkin | common | 12.0 | 5 |
| `card-skin-sakura` *(new)* | cardSkin | common | 11.0 | 5 |
| `card-skin-midnight` *(new)* | cardSkin | common | 10.0 | 5 |
| `card-skin-citrus` *(new)* | cardSkin | common | 7.0 | 4 |
| `comfort-star-fragments` *(existing)* | fragment | comfort | 10.0 | 3 |

Sum: `4+3 + 4+3 + 9+7+2 + 8+7+3 + 12+11+10+7 + 10 = 100.0`. ✓

Notes:
- The `badge-anniversary-lantern` is the requested **special-event badge** (rare, lowest 2.0 weight). It is still a normal decorative `badge` category row so no schema/UI branch is needed; "special event" is conveyed via its name/description copy.
- IDs are stable strings; `user_assets.prize_id` references them, so **never rename an existing id**. New ids are additive.
- `chooseLotteryPrize` already normalizes by total weight (`lottery_policy.dart:70-79`), so 100 is a convention the test enforces, not a runtime requirement — keep it 100 to satisfy `lottery_policy_test.dart`.

## 4. Prize-pool display redesign (`lucky_draw_screen.dart`)

Replace the flat `_ProbabilityList` (lines 195-245) with a **grouped, rarity-aware** layout using Cozy Quest primitives:

- Group prizes by `category` (order: avatarFrame, profileBackground, badge, title, cardSkin, fragment). Each group is one `AppCard` with a `SectionHeader`-style title using `displayLotteryCategory(...)`.
- Within a group, one row per prize: name + an `AppPill` whose `PillVariant` maps from rarity (`rare → primary`, `uncommon → xp`, `common → neutral`, `comfort → streak`/success) showing `rarityLabel`, and the probability `%` right-aligned (reuse `_formatProbability`).
- Keep the existing summary `AppCard` (cost line, balance, inventory count, "no boost" pill) unchanged.
- Add an **"View my assets"** `AppSecondaryButton` below the draw button routing to `/discover/assets` (new entry point #1). The post-draw success dialog's "View assets" action (`lucky_draw_screen.dart:180-188`) currently navigates to `/profile`; redirect it to `/discover/assets` (entry point #2).
- All copy via `AppLocalizations`; no hard-coded strings.

## 5. New Asset Inventory screen

- File: `linguaquest/lib/features/discover/asset_inventory_screen.dart`.
- Route: `GoRoute(path: '/discover/assets')` registered next to `/discover/lucky-draw` in `app_router.dart` (~line 234). `selectedTabIndex` mapping keeps `/discover*` → tab 3 (already handled by `path.startsWith('/discover')` at `app_router.dart:324`).
- Data: reuse `GET /lottery/assets` → `state.userAssets` (already loaded into `AppState`; the lucky-draw screen reads `state.userAssets` at `lucky_draw_screen.dart:50`). Trigger a refresh in `initState` via the existing assets-load path (mirror `achievements_screen.dart:18-24` pattern; reuse whatever `appController` method already fetches assets after a draw).
- Structure:
  - `AppBar` title = `l10n.assetInventoryTitle`, `FallbackBackButton(fallbackLocation: '/discover/lucky-draw')`.
  - Header `AppCard`: total owned count (`Σ quantity`) and total fragment value (`Σ asset.totalFragments`) as `AppPill`s.
  - Sections grouped by `category` (same order as §4). Empty categories hidden. Empty overall → `MascotEmptyState` with `l10n.assetInventoryEmpty`.
  - Per asset: name, `categoryLabel` + `rarityLabel`, quantity badge (`AppPill` `×{quantity}` when > 1), and `totalFragments` hint. Comfort/fragment assets (`asset.category == 'fragment'`) show fragment total prominently.
- Entry points: (1) lucky-draw "View my assets" button, (2) post-draw dialog action (both §4). Optionally a Profile tile — listed as an open decision (§10), not required.

## 6. New achievements

Server `AchievementPolicy.evaluate(...)` (and client `AchievementEvaluator.evaluate(...)`) gain 4 entries. To feed them, `evaluate` gains 4 new parameters; `GET /achievements` (`routes.dart:892-911`) computes them from existing/derived stats.

| id | title (en) | condition | evaluation source (concrete) |
| --- | --- | --- | --- |
| `learn_100_words` | Century Scholar | `masteredWords >= 100` | Already computed at `routes.dart:898-900` (`user_words` where `mastery_level >= 4`). **No new signal** — just a new threshold reusing `masteredWords`. |
| `quiz_perfect` | Flawless Run | first quiz/lesson session with 100% correct | Derive a `bool hasPerfectQuiz` server-side from `exercise_records` (`database.dart:243-256`): group by `session_id`, true if any session has `COUNT(*) >= 4 AND bool_and(is_correct)`. New read-only query `hasPerfectSession(uid)` — **no new table/column**. |
| `first_listening` | First Echo | completed ≥1 listening exercise | Derive `bool hasListening` from `exercise_records` where `prompt_type IN ('listeningWordChoice', ...)` **or** `dimension = 'listening'`. New read-only query `hasListeningRecord(uid)` — **no new table/column**. (Confirm the exact `promptType`/`dimension` the listening training posts; recommendation uses `exerciseType: 'listeningWordChoice'` at `routes.dart`/`mock_repositories.dart:1349`.) |
| `first_map_language` | Cartographer | first time the user picks a language on the language map (§1.1) | **No signal exists yet.** Minimal new signal required (§6.1). |

Naming/threshold rationale: `learn_100_words` extends the existing 10/50 mastered ladder; `quiz_perfect`/`first_listening` are one-shot booleans (cheap to evaluate, no counters); `first_map_language` is a one-shot flag.

Icons (existing `iconKey` convention, material symbol names): `learn_100_words → workspace_premium`, `quiz_perfect → verified`, `first_listening → hearing`, `first_map_language → map`.

### 6.1 Minimal new triggers

Two of the four need a signal that does not exist today. Keep each minimal:

- **`quiz_perfect`** — *no new signal/event.* Use the existing `exercise_records` rows already POSTed by the quiz flow (`POST /exercise-records`, `routes.dart:548-577`). Add only a read query. Risk: relies on a session having ≥4 records and all correct; if the quiz posts records per-question this works as-is (verify the quiz actually posts exercise records — open decision §10).
- **`first_listening`** — *no new signal/event.* Same `exercise_records` source, filtered by listening `prompt_type`/`dimension`. Add only a read query. Risk: depends on the listening trainer tagging its records with a stable `promptType`/`dimension`; verify and, if absent, the minimal add is to ensure the listening exercise sets `dimension='listening'` (or `promptType='listeningWordChoice'`) when posting — a one-field change in the app's exercise-record payload, no schema change.
- **`first_map_language`** — *minimal new flag needed.* The language map (§1.1) selection currently persists no server-visible flag. Minimal signal: add a nullable column `users.first_map_language_at TIMESTAMPTZ` (idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, matching the `database.dart:149` migration pattern) set on first map selection via a tiny endpoint or piggy-backed on the existing profile/target-language update. Achievement unlocks when `first_map_language_at IS NOT NULL`. If the map already writes `targetLanguage` to the user row on selection, reuse a `target_language_set_at` style timestamp instead of a new column (open decision §10). For offline Mock parity, gate on a `SharedPreferences` flag written when the map screen confirms a selection.

If a signal cannot be wired this milestone, ship the other 3 and mark `first_map_language` as "defined, pending §1.1 map-selection trigger" rather than faking it.

## 7. Duplicate handling — verify & document (no rebuild)

Already correct and must be preserved:
- DB: `user_assets UNIQUE (uid, prize_id)` (`database.dart:405`) + draw insert `ON CONFLICT (uid, prize_id) DO UPDATE SET quantity=user_assets.quantity + 1` (`database.dart:1526-1533`). Drawing a duplicate increments `quantity`; it does not create a new asset row.
- Fragment value: `user_assets.fragment_value` is stored per asset; the app exposes `UserAsset.totalFragments = fragmentValue * quantity` (`lottery.dart:114`). This is the "convert to fragments" surface — every owned/duplicate asset carries an accumulable fragment value.
- Mock parity: `MockLotteryRepository` must apply the same quantity+1 / fragment accounting on duplicate draws (verify `_saveAssets`/draw path at `mock_repositories.dart:556-700` increments `quantity` on existing `prizeId`).

Action: add/confirm a server test that drawing the same prize twice yields one `user_assets` row with `quantity == 2` and `totalFragments == 2 * fragmentValue`. Document this invariant in the test; do not change the SQL.

## 8. Mock-repo parity

- `_mockPrizePool` (`mock_repositories.dart:707-762`) must be replaced with the **exact 15 prizes** from §3 (same ids, categories, rarities, probabilities, fragmentValues) so offline draw odds match the server.
- `MockLotteryRepository` duplicate path must mirror quantity+1 accumulation (§7).
- `MockLearningRepository.getAchievements` (`mock_repositories.dart:1333-1342`) must call the expanded `AchievementEvaluator.evaluate(...)` with the 4 new params, sourced from `LearningAnalytics.mock()` plus mock booleans/flags (e.g. mock `hasPerfectQuiz=true`, `hasListening=true`, `hasMapLanguage=false`, `masteredWords` from analytics) so the achievements screen shows the new rows offline.
- Client `AchievementEvaluator.evaluate` signature must stay in lockstep with server `AchievementPolicy.evaluate` (both gain the 4 params).

## 9. Test plan

**Server (`dart test` in `server/`)**
- `lottery_policy_test.dart` (update existing): `probabilityTotal == 100`; category set still `containsAll([avatarFrame, profileBackground, badge, title, cardSkin, fragment])`; still excludes `learningBoost`/`scoreBoost`; assert 15 prizes and all ids unique.
- New `achievement_policy_test.dart`: `learn_100_words` unlocks at `masteredWords >= 100` and not at 99; `quiz_perfect`/`first_listening`/`first_map_language` unlock iff their respective bool/flag is true; existing 6 unchanged; total = 10 achievements.
- New/extended `routes_test.dart` or DB test: drawing same prize twice → one `user_assets` row, `quantity == 2`; `GET /achievements` reflects new entries from seeded `exercise_records`/`user_words`.

**Flutter (`flutter test` in `linguaquest/`)**
- `asset_inventory_screen` widget test: renders grouped sections + quantity badges from a seeded `userAssets` list; empty state shows `MascotEmptyState`.
- `lucky_draw_screen` widget test: expanded pool (15 prizes) all rendered, grouped by category, rarity pill present; "View my assets" button navigates to `/discover/assets`.
- `achievements_screen` widget test: shows 10 tiles; new titles localized (no raw English when locale = zh).
- Mock parity test: `MockLotteryRepository.prizePool()` returns 15 prizes whose probabilities sum to 100 (mirrors server).

**Guardrails**: `flutter analyze` + `flutter gen-l10n` (commit generated output) clean.

## 10. l10n keys to add (en / zh / ms)

Add to `app_en.arb` (template), `app_zh.arb`, `app_ms.arb`, then `flutter gen-l10n`.

Prize names & descriptions (one `lotteryPrize_<id>_name` + `_desc` per **new** prize; existing 6 names stay where they are — currently server-supplied Chinese, see open decision §10):
- `lotteryPrizeEmberFrameName/Desc`, `lotteryPrizeDawnHarborBgName/Desc`, `lotteryPrizeNightOwlBadgeName/Desc`, `lotteryPrizeAnniversaryLanternName/Desc`, `lotteryPrizeLexiconKeeperTitleName/Desc`, `lotteryPrizeDawnVoyagerTitleName/Desc`, `lotteryPrizeSakuraSkinName/Desc`, `lotteryPrizeMidnightSkinName/Desc`, `lotteryPrizeCitrusSkinName/Desc`.

Achievements (title + description per new id):
- `achievementLearn100Title/Desc`, `achievementQuizPerfectTitle/Desc`, `achievementFirstListeningTitle/Desc`, `achievementFirstMapLanguageTitle/Desc`.
- Localize existing achievements screen chrome (currently hard-coded `achievements_screen.dart:35,44,45,110`): `achievementsScreenTitle`, `achievementsHeaderTitle`, `achievementsUnlockedCount(unlocked, total)`, `achievementUnlockedLabel`.

Asset inventory UI:
- `assetInventoryTitle`, `assetInventoryEmpty`, `assetInventoryTotalOwned(count)`, `assetInventoryTotalFragments(count)`, `assetInventoryQuantityBadge(count)`, `luckyDrawViewMyAssets` (button), and reuse existing `luckyDrawViewAssets`.

(Existing prize/category/rarity localization helpers `displayLotteryCategory`/`displayLotteryRarity` in `ui_labels.dart` already cover the 6 categories + 4 rarities — no new category/rarity keys needed since all new prizes reuse them.)

## 11. Open decisions

1. **Prize name localization model.** Prize `name`/`description` are currently stored server-side in Chinese and sent verbatim (`lottery_policy.dart`). Options: (a) keep server names as canonical Chinese and add a client-side `localizePrizeName(id)` override map keyed by id (recommended, no server i18n infra), or (b) send a stable `nameKey` from the server and resolve fully client-side. Pick (a) for minimal change.
2. **`first_map_language` signal location.** New `users.first_map_language_at` column vs. reusing an existing target-language timestamp written by §1.1's map screen. Depends on whether §1.1 already persists a server-visible selection event.
3. **Does the quiz actually POST `exercise_records`?** `quiz_perfect`/`first_listening` assume yes. Must verify the quiz/lesson flow calls `POST /exercise-records` with per-question rows and a stable listening tag before committing to the `exercise_records`-derived evaluation; otherwise add the minimal one-field tag.
4. **Profile entry point to Asset Inventory** (in addition to lucky-draw): nice-to-have, not required.
5. **Fragment redemption** (spending `totalFragments`) is explicitly deferred — confirm §7 only wants accumulation/display now.

## 12. Risks

- **Probability rebalancing**: lowering rare/comfort weights changes player-perceived odds. Mitigation: keep comfort+common ≥ 50% combined (here 10 + 40 = 50) so the "always get something" feel is preserved; lock the 100-sum with `lottery_policy_test.dart`. Mock pool must be byte-for-byte consistent or offline/online odds diverge.
- **Achievement triggers that don't exist yet**: `first_map_language` has no server signal today; `quiz_perfect`/`first_listening` depend on `exercise_records` being posted with the right tags. If unverified, these silently never unlock. Mitigation: verify the post paths (open decision §3) and ship only the wired achievements, marking the rest "pending trigger".
- **Client/server evaluator drift**: `AchievementEvaluator` (app) and `AchievementPolicy` (server) must change in lockstep (same ids, thresholds, params) or online vs. offline users see different unlock states. Mitigation: shared test asserting identical id list + thresholds.
- **Stable prize ids**: renaming an existing prize id orphans `user_assets.prize_id` foreign-key rows. Mitigation: only add new ids; never rename.
- **i18n unfreeze scope creep**: localizing the previously-hard-coded achievements screen touches untranslated strings; keep additions limited to the enumerated keys in §10.
