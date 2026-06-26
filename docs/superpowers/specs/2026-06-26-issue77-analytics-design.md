# Design Spec: Issue #77 §3 「学习分析」— Polished Learning Report

**Date:** 2026-06-26
**Issue:** #77 §3 学习分析
**Status:** Draft (design only — no code)
**i18n:** UNFROZEN (new ARB keys allowed)

---

## 1. Overview & Mapping to §3

Issue #77 §3 asks to turn the existing analytics screen into a polished **"learning report"** (学习报告) with more chart types and more metrics, styled consistently with the existing LinguaQuest "Cozy Quest" UI.

Today the screen (`lib/features/quests/progress_analytics_screen.dart`) is a `ListView` of stat cards plus **one** hand-rolled custom-painter-style bar chart (`_SevenDayXpChart`, lines 245–293 — actually a `Row` of `Container` bars, not a real `CustomPainter`). It mixes client-computed metrics (from `state.reviewWords`, `state.dueWords`) with a server `LearningAnalytics` snapshot that today is **pure mock** (`server/lib/src/routes.dart:835–840` returns `LearningAnalytics.mock()`).

This spec delivers, on **one screen**:

| §3 ask | This spec |
| --- | --- |
| More chart types | Add **5** chart kinds: line (XP trend), bar (per-modality accuracy), pie/ring (mastery distribution), radar (5 ability dimensions), and keep/migrate the 7-day bar to `fl_chart`. |
| More metrics | 12 metrics in a structured grid + chart annotations (see §6). |
| Polished report matching LinguaQuest UI | Restructured into titled sections built from Cozy Quest primitives (`AppCard`, `SectionHeader`, `AppPill`, `AppProgressBar`), charts themed with `AppTokens`/`AppTheme` palette. |
| Real data | Extend server `GET /analytics` to compute **real aggregates** from existing DB tables; prefer client-side computation where AppState already has the data. |

---

## 2. Scope

### In scope
- Add `fl_chart` dependency.
- Add 4 new chart types + migrate the existing 7-day bar to `fl_chart` (5 charts total).
- Extend `LearningAnalytics` model with new (defaulted) fields + Mock parity + `fromJson`/`toJson`.
- Replace the mock `GET /analytics` body with **real SQL aggregation** over existing tables (`user_words`, `custom_words`, `study_sessions`, `review_events`, `exercise_records`, `users`). No new tables.
- Restructure `progress_analytics_screen.dart` into a sectioned "learning report".
- New l10n keys (en/zh/ms) for chart titles + metric labels.
- Tests: server aggregation test; Flutter widget test that the screen renders all charts without crashing from a seeded `LearningAnalytics`.

### Out of scope
- New DB tables/columns (everything is grounded in existing schema).
- Date-range pickers / interactive drill-down / CSV export.
- New navigation routes (stays a single screen reached from `/quest`).
- Leaderboard / achievements redesign (separate concerns; untouched).
- Dark-mode-specific chart theming (app is light-only per project memory).

---

## 3. fl_chart Dependency Note

`pubspec.yaml` currently has **no charting library** (verified — deps are dio, riverpod, go_router, flutter_map, etc.). The existing 7-day "chart" is a manual `Row` of sized `Container`s.

**Decision:** add `fl_chart`, the de-facto Flutter charting library, which provides `LineChart`, `BarChart`, `PieChart`, and `RadarChart` in one package — exactly the four families §3 needs. Adding one dependency to serve 4–5 chart types is justified, not over-engineering; the alternative (hand-rolling a `CustomPainter` per chart type, especially radar) is materially more code and harder to theme/test.

```bash
cd linguaquest
flutter pub add fl_chart   # pins the latest version compatible with Dart sdk ^3.11.4
```

Pin the resolved version in `pubspec.yaml` (e.g. `fl_chart: ^1.x.x` — whatever `pub add` resolves) and commit `pubspec.lock`.

**Migration note:** replace `_SevenDayXpChart` with an `fl_chart` `BarChart` (or `LineChart`, see chart inventory) for visual consistency with the new charts. The old widget is deleted.

---

## 4. Chart Inventory

All charts live inside `AppCard`s, titled by a `SectionHeader` or a `titleMedium` label, and themed from the `AppTheme`/`AppTokens` palette (`AppTheme.mango`, `.cyan`, `.coral`, `.success`, `AppTokens.primarySoftText`). Bars/lines use rounded caps; gridlines use `colorScheme.outlineVariant`; no legends heavier than small `AppPill`/dot+label rows.

| # | Chart | Metric shown | Data source | fl_chart widget |
| --- | --- | --- | --- | --- |
| C1 | **Line chart** | XP trend over time | `sevenDayXp` (existing); model extends to `dailyXp` (up to 14/30 pts) if server supplies | `LineChart` (`LineChartData` + one `LineChartBarData`, gradient mango→success, dots off, area fill ~0.15) |
| C2 | **Bar chart** | Per-modality accuracy: meaning / listening / spelling / context (%) | NEW server field `modalityAccuracy` (from `exercise_records`/`review_events`); fallback to client averages of CustomWord dimension scores | `BarChart` (4 `BarChartGroupData`, one rod each, colored per modality) |
| C3 | **Pie / ring (donut) chart** | Word mastery distribution: new / learning / mastered | Client-side from `state.reviewWords` (`masteryLevel` buckets) — **no server change** | `PieChart` (3 `PieChartSectionData`, `centerSpaceRadius` > 0 for donut, center label = total) |
| C4 | **Radar / ability-dimension chart** | 5 ability dims: meaning recognition, meaning recall, context, listening, spelling | Client-side averages of CustomWord per-dimension scores (`meaningRecognitionScore`, `meaningRecallScore`, `contextScore`, `listeningScore`, `spellingScore`) across `state.reviewWords` — **no server change** | `RadarChart` (single `RadarDataSet` of 5 entries 0–100, ticks 0/50/100) |
| C5 | **Bar chart (migrated)** | 7-day XP (kept) — may be folded into C1 if the line covers 7-day; otherwise a small weekly bar | `sevenDayXp` (existing) | `BarChart` replacing `_SevenDayXpChart` |

> If C1 already renders the 7-day XP as a line, **C5 is dropped** to avoid redundancy (open decision §10). Default recommendation: keep **C1 line = trend** and **drop C5**, since two XP charts on one screen is noise.

**Why C3 & C4 are client-side:** `CustomWord` already carries `masteryLevel` and the 5 dimension scores (`lib/data/models/custom_word.dart:72–79`), and `AppState` already exposes `reviewWords`/`weakWords`/`dueWords` (`app_state.dart:259–303`). These charts need **zero** server/model change — compute in the widget. This is the YAGNI-correct choice.

---

## 5. Metric Table (metric → source)

Source legend: **[C]** client-state (already in `AppState`, no server/model change) · **[S]** server-aggregate (compute in `GET /analytics`, carried by an existing or new model field) · **[N]** new model field needed (defaulted) in addition to server compute.

| Metric (§3) | Source | Where it comes from |
| --- | --- | --- |
| Learned words total | [S] | existing `learnedWords` field; server: `COUNT(user_words) WHERE status NOT IN ('New','Previewed','Ignored')` (+ custom_words). Today mock-only. |
| Mastered count | [S] | existing `masteredWords`; server: `COUNT WHERE mastery_level >= 4`. Also derivable [C] from `reviewWords` (screen already does, line 43). |
| Current review-queue (due) | [C] | `state.dueWords.length` — already computed (`app_state.dart:261`). No server needed. |
| Today XP | [C]/[S] | `state.todayTrainingXp` ([C], app_state.dart:166) for training; total today XP [S] from `study_sessions`/`review_events` if a daily figure is wanted (`SUM(xp_earned) WHERE started_at::date = today`). |
| Week XP | [S] | derived from `sevenDayXp` list (sum); list itself [S] from `study_sessions.xp_earned` grouped by day. |
| Quiz accuracy (meaning) | [S]→**[N]** `modalityAccuracy.meaning` | `exercise_records`/`review_events`: `AVG(is_correct)` for meaning prompt types. Fallback [C]: avg of `meaningRecognitionScore`. |
| Listening accuracy | [S]→**[N]** `modalityAccuracy.listening` | `exercise_records` where `prompt_type`/`dimension` = listening. Fallback [C]: avg `listeningScore`. |
| Spelling accuracy | [S]→**[N]** `modalityAccuracy.spelling` | `exercise_records` spelling prompts. Fallback [C]: avg `spellingScore`. |
| Weak-word count | [C] | `state.weakWords.length` — already computed (`app_state.dart:288`, `CustomWord.isWeak`). No server. |
| Top error types | [S] | existing `weakestExerciseType` + `mostMissedWordIds`; server: `exercise_records` grouped by `prompt_type`/`dimension` ordered by wrong rate; mostMissed from `review_events`/`user_words.wrong_count DESC`. Today mock. |
| Streak days | [C]/[S] | `state.user.streak` [C]; server `users.streak`. Existing `streakDays` field. |
| Study-plan completion rate | [C]→**[N]** `studyPlanCompletionPct` | client has `studyPlan` + `dailyReviewLimit` (`app_state.dart:204`); can compute today's completion [C]. If a historical rate is desired, [S] from `daily_activity`/`study_sessions`. Recommend **[C]** today-rate to avoid server work. |

**Net new model fields needed (§7):** `modalityAccuracy` (map of meaning/listening/spelling/context → %), optional `dailyXp` (longer trend than 7-day), optional `topErrorTypes` (richer than single `weakestExerciseType`). Everything else reuses existing fields or is computed client-side.

---

## 6. `LearningAnalytics` Model Additions

File: `lib/data/models/analytics.dart`. Add fields with **safe defaults** so `fromJson` stays backward-compatible (the model already defaults every field — keep that pattern) and so demo/mock parity holds.

New fields (all defaulted):

| Field | Type | Default | Purpose / chart |
| --- | --- | --- | --- |
| `modalityAccuracy` | `Map<String,int>` (keys: `meaning`,`listening`,`spelling`,`context`) | `{}` | C2 bar chart, accuracy metrics |
| `dailyXp` | `List<int>` (0–30 entries) | `const []` | C1 line trend beyond 7 days; if empty, C1 falls back to `sevenDayXp` |
| `topErrorTypes` | `List<String>` (ordered worst-first) | `const []` | "Top error types" metric; fallback to `[weakestExerciseType]` |

`fromJson`: parse with the existing `?? default` style (map via `(j['modalityAccuracy'] as Map?)?.map(...) ?? const {}`).
`toJson`: include the three keys.
`mock()`: add representative values, e.g. `modalityAccuracy: {'meaning':84,'listening':71,'spelling':63,'context':77}`, `dailyXp: [120,80,95,110,70,130,45,100,90,...]` (14 entries), `topErrorTypes: ['spelling','listening']`. This keeps offline demo mode and `MockAnalyticsRepository` (`mock_repositories.dart:1326`) fully functional with the richer UI.

No change to `MockAnalyticsRepository.getAnalytics` body beyond what `mock()` returns. `ApiAnalyticsRepository` (`api_repositories.dart:830`) is unchanged — it already does `LearningAnalytics.fromJson(response.data!)`, which will pick up the new keys automatically.

---

## 7. Server `GET /analytics` Real-Aggregation Plan

File: `server/lib/src/routes.dart:835–840` — currently `return jsonResponse(LearningAnalytics.mock().toJson())`. Replace the mock with real per-user SQL. All tables below **exist today** in `database.dart` (verified line numbers in parens).

| Output field | SQL source (grounded in real schema) |
| --- | --- |
| `learnedWords` | `user_words` (158) + `custom_words` (105): `COUNT WHERE uid=$uid AND status NOT IN ('New','Previewed','Ignored')`. |
| `masteredWords` | same tables: `COUNT WHERE mastery_level >= 4`. |
| `streakDays` | `users.streak` (57). |
| `totalStudyDays` | `daily_activity` (326) distinct day count, or `COUNT(DISTINCT started_at::date)` from `study_sessions` (203). |
| `sevenDayXp` / `dailyXp` | `study_sessions` (203): `SUM(xp_earned) GROUP BY started_at::date` over last 7/14 days, zero-filled per day. |
| `todayMinutes`/`totalMinutes` | `study_sessions`: `SUM(EXTRACT(epoch FROM ended_at-started_at)/60)` total and for `started_at::date=today`. |
| `averageAccuracyPct` | `review_events` (221): `AVG(is_correct)::int*100`, or from `exercise_records`. |
| `modalityAccuracy` (**new**) | `exercise_records` (243): `AVG(is_correct) GROUP BY prompt_type` (or `dimension`) → bucket into meaning/listening/spelling/context. **This is the key new aggregation — and the data exists** (see §9). |
| `weakestExerciseType` / `topErrorTypes` | `exercise_records` grouped by `prompt_type`/`dimension` ordered by wrong rate ascending-correct. |
| `mostMissedWordIds` | `review_events` or `user_words.wrong_count DESC LIMIT N`. |
| `wordbookProgressPct` | `user_words`: mastered ÷ total per `word_book_id` (the `word_book_id` column exists, line ~163). |
| `achievementCount`, `trainingXp`, `trainingRank` | keep existing logic / mock fallback as today (not §3-critical). |

**Minimal-change rule:** isolate the aggregation in a new helper (e.g. `analytics_policy.dart` alongside the other `*_policy.dart` files) per the repo convention, keeping `routes.dart` thin. Wrap in graceful fallback: if a query returns no rows (new user), default to `0`/`{}` (or `LearningAnalytics.mock()` for a friendlier empty state — open decision §10).

**Client-preferred metrics (NO server change):** due count, weak-word count, mastery distribution (C3), ability radar (C4), study-plan today-completion — all from `AppState`. The screen already does this for several values; we keep and extend that.

---

## 8. Redesigned Screen Structure

`progress_analytics_screen.dart` stays **one screen**, restructured as a top-to-bottom "learning report". Each section is a `SectionHeader` + one or more `AppCard`s.

```
AppBar: l10n.questAnalytics  (FallbackBackButton → /quest)
ListView(padding 20):
  1. SectionHeader(analyticsReportTitle / analyticsReportSubtitle)

  2. ── Summary band ──  (existing _ProgressSignals, kept)
     AppCard row: cards · mastered · trainingXP · accuracy

  3. ── XP Trend ──  SectionHeader(analyticsXpTrendTitle)
     AppCard → C1 LineChart (dailyXp || sevenDayXp)
     metric chips: weekXp, todayXp (AppPill)

  4. ── Ability Radar ──  SectionHeader(analyticsAbilityTitle)
     AppCard → C4 RadarChart (5 dims from reviewWords) [client]

  5. ── Modality Accuracy ──  SectionHeader(analyticsModalityTitle)
     AppCard → C2 BarChart (meaning/listening/spelling/context)

  6. ── Word Mastery ──  SectionHeader(analyticsMasteryTitle)
     AppCard → C3 ring/donut PieChart (new/learning/mastered) [client]
     + AppProgressBar review-load (existing, kept)

  7. ── Detailed Stats ──  (existing _ExtendedAnalyticsSection grid, kept & relabeled via l10n)
     streak, study days, learned, today/total minutes, wordbook %, weak-word count, due count

  8. ── Focus / Recommendations ──  (existing _RecommendedPracticeSection, kept)
```

Hard-coded English strings currently in the file (`'Detailed Stats'`, `'7-Day XP Trend'`, `'Focus Area'`, `'Recommended Practice'`, `'复习负荷'` etc.) are replaced with l10n keys (§9). Charts render inside `AppCard` so they inherit the single soft `cardShadow`. Empty/new-user state: when `analyticsSnapshot == null`, keep the existing `CircularProgressIndicator`; when a chart's data is all-zero, show a `MascotEmptyState`-style placeholder rather than an empty chart.

---

## 9. Does per-modality accuracy data actually exist in the DB?

**Yes.** Two real tables support it:

- **`exercise_records`** (`database.dart:243`) has `prompt_type TEXT`, `is_correct BOOLEAN`, `dimension TEXT DEFAULT 'confidence'`, `word_id`, `answer_time_ms`. `AVG(is_correct) GROUP BY prompt_type` (or `dimension`) gives true per-modality accuracy.
- **`review_events`** (`database.dart:221`) has `is_correct`, `answer_time_ms`, `wrong_option`, `mastery_before/after` — supports overall accuracy and most-missed analysis.
- Additionally, **`user_words`/`custom_words`** carry per-dimension scores (`meaning_recognition_score`, `meaning_recall_score`, `spelling_score`, `listening_score`, `context_score`) — these power the **radar chart entirely client-side** with zero server work, and serve as a **fallback** for modality accuracy when a user has too few `exercise_records` rows.

So C2 (modality bar) has a real server source, and C4 (radar) has a real client source. No table needs to be invented.

---

## 10. l10n Keys to Add (en / zh / ms)

i18n is UNFROZEN. Add to `app_en.arb` (template), `app_zh.arb` (runtime default), `app_ms.arb`, then `flutter gen-l10n`. Reuse existing keys where present (`questAnalytics`, `analyticsCards`, `analyticsAccuracy`, `analyticsTrainingXp`, `homeMastered`, `analyticsAssetsDue`).

| Key | en | zh | ms |
| --- | --- | --- | --- |
| `analyticsReportTitle` | Learning report | 学习报告 | Laporan pembelajaran |
| `analyticsReportSubtitle` | Your progress, charts, and focus areas | 你的进度、图表与重点 | Kemajuan, carta dan fokus anda |
| `analyticsXpTrendTitle` | XP trend | 经验值趋势 | Trend XP |
| `analyticsAbilityTitle` | Ability dimensions | 能力维度 | Dimensi keupayaan |
| `analyticsModalityTitle` | Accuracy by type | 各题型正确率 | Ketepatan ikut jenis |
| `analyticsMasteryTitle` | Word mastery | 单词掌握度 | Penguasaan perkataan |
| `analyticsDetailTitle` | Detailed stats | 详细数据 | Statistik terperinci |
| `analyticsFocusTitle` | Recommended practice | 推荐练习 | Latihan disyorkan |
| `analyticsReviewLoad` | Review load | 复习负荷 | Beban ulang kaji |
| `analyticsWeekXp` | This week XP | 本周经验 | XP minggu ini |
| `analyticsTodayXp` | Today XP | 今日经验 | XP hari ini |
| `analyticsWeakWords` | Weak words | 薄弱单词 | Perkataan lemah |
| `analyticsDueNow` | Due now | 待复习 | Perlu ulang kaji |
| `analyticsMasteryNew` | New | 新词 | Baharu |
| `analyticsMasteryLearning` | Learning | 学习中 | Belajar |
| `analyticsMasteryMastered` | Mastered | 已掌握 | Dikuasai |
| `analyticsDimMeaningRecognition` | Recognition | 认词 | Pengecaman |
| `analyticsDimMeaningRecall` | Recall | 回忆 | Ingatan |
| `analyticsDimContext` | Context | 语境 | Konteks |
| `analyticsDimListening` | Listening | 听力 | Mendengar |
| `analyticsDimSpelling` | Spelling | 拼写 | Ejaan |
| `analyticsModalityMeaning` | Meaning | 词义 | Makna |
| `analyticsModalityListening` | Listening | 听力 | Mendengar |
| `analyticsModalitySpelling` | Spelling | 拼写 | Ejaan |
| `analyticsModalityContext` | Context | 语境 | Konteks |
| `analyticsTopErrors` | Top error types | 主要错误类型 | Jenis ralat utama |

(zh/ms strings are first-pass; finalize with the translator. Keep existing `analyticsDataTitle`/`analyticsDataSubtitle` or alias to the new report title.)

---

## 11. Testing Approach

**Server (only if server changed):**
- New `server/test/analytics_aggregation_test.dart` (or extend an existing policy test): seed a user with rows in `study_sessions`, `review_events`, `exercise_records`, `user_words`; call the aggregation helper (`analytics_policy`) and assert: `learnedWords`/`masteredWords` counts, `sevenDayXp` zero-filling, and `modalityAccuracy` percentages per `prompt_type`. Run `dart test`. Evidence: paste actual `dart test` output (per repo anti-laziness rule — no "tests pass" without output).
- Edge cases: new user with no rows → all-zero / empty maps (no crash, no divide-by-zero).

**Flutter:**
- `test/features/quests/progress_analytics_screen_test.dart`: pump `ProgressAnalyticsScreen` with `appControllerProvider` overridden to a state carrying a seeded `LearningAnalytics` (with non-empty `modalityAccuracy`, `dailyXp`) and a seeded `reviewWords` list (varied `masteryLevel` + dimension scores). Assert the screen builds without exceptions and that each chart widget type is present (`find.byType(LineChart)`, `BarChart`, `PieChart`, `RadarChart`).
  - **fl_chart renders in `flutter test`** (it paints to the test canvas; no platform channels) — golden tests are optional, presence/no-throw tests are sufficient.
- Metric-correctness unit tests (pure functions): extract C3 bucketing and C4 dimension-averaging into small testable helpers and assert outputs for a known `reviewWords` fixture (e.g. 10 words → expected new/learning/mastered split, expected radar averages).
- `flutter analyze` + full `flutter test` must pass before PR (repo convention). Paste output.

---

## 12. Open Decisions

1. **fl_chart vs custom painters** — recommend **fl_chart** (one dep, 4 chart families, themeable, testable). Confirm acceptable to add a dependency.
2. **C1 line vs keep C5 bar (7-day)** — recommend C1 line as the single XP-trend chart and **drop** the duplicate 7-day bar. Confirm.
3. **Which metrics server vs client** — recommend: modality accuracy + learned/mastered counts + XP trend = **server**; due count, weak count, mastery pie, ability radar, plan-completion = **client**. Confirm split.
4. **Time window for trend** — 7-day (reuse `sevenDayXp`, no model change) vs 14/30-day (`dailyXp` new field, server change). Recommend ship 7-day first; `dailyXp` optional.
5. **New-user empty state** — return real zeros (honest but sparse) vs keep `mock()` fallback (friendlier demo). Recommend zeros for authenticated users, mock for offline demo mode.
6. **`prompt_type` vs `dimension`** for modality bucketing in `exercise_records` — confirm which column maps cleanly to meaning/listening/spelling/context (both exist; `dimension` defaults to `'confidence'`, so verify it's populated meaningfully before relying on it; `prompt_type` may be the safer key).

---

## 13. Risks

| Risk | Mitigation |
| --- | --- |
| fl_chart fails to render in widget tests | It paints to canvas without platform channels; use presence/no-throw assertions, avoid goldens. Verify early with a smoke test before building all 5 charts. |
| Real per-modality data sparse for new users | `exercise_records` may be empty → modality bar all-zero. Fall back to **client-side dimension-score averages** (CustomWord scores) when row count is low; show `MascotEmptyState` if truly no data. |
| `dimension` column under-populated (`DEFAULT 'confidence'`) | Prefer `prompt_type` for bucketing (open decision §10/#6); validate against real rows in the aggregation test. |
| Model field additions break `fromJson` for old payloads | All new fields are **defaulted** (existing pattern) — old/mock JSON still parses. |
| Server aggregation slows `/analytics` | Queries hit indexed columns (`idx_user_words_uid_next_review`, `idx_custom_words_uid_next_review`); group-bys are per-user small. Add `uid` filters; acceptable. |
| Chart over-crowding on small screens | One chart per `AppCard`, vertical stack, `ListView` scroll; charts get fixed heights (~160–200px) to avoid layout overflow. |
| Two XP charts redundant | Drop C5 (open decision #2). |

---

## 14. Files Touched (summary)

- `linguaquest/pubspec.yaml` — add `fl_chart`.
- `linguaquest/lib/data/models/analytics.dart` — new fields + mock + json.
- `linguaquest/lib/features/quests/progress_analytics_screen.dart` — restructure into report, replace `_SevenDayXpChart` with fl_chart charts, add radar/pie/bar/line, l10n-ize strings.
- `linguaquest/lib/l10n/app_{en,zh,ms}.arb` + `flutter gen-l10n`.
- `server/lib/src/routes.dart` (`GET /analytics`) + new `server/lib/src/analytics_policy.dart` — real aggregation.
- Tests: `server/test/analytics_aggregation_test.dart`, `linguaquest/test/features/quests/progress_analytics_screen_test.dart`.
- `MockAnalyticsRepository` / `ApiAnalyticsRepository` — unchanged (mock parity via `mock()`; api auto-parses new keys).
