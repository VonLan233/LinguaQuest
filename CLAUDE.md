# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This repo holds two independent Dart projects:

- `linguaquest/` — the Flutter mobile app (Android-first). This is where almost all work happens.
- `server/` — an optional Dart `shelf` API backend with PostgreSQL. The app does **not** require it.

Run commands from inside the relevant project directory, not the repo root.

## Common commands

Flutter app (`cd linguaquest`):

```bash
flutter pub get
flutter run                                                # offline demo mode (mock repos)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 # against local backend (Android emulator host)
flutter analyze
flutter test
flutter test test/spaced_repetition_test.dart             # single test file
flutter test --name "UI style guardrails"                 # single test by name
flutter gen-l10n                                            # regenerate localizations after editing .arb files
flutter build apk --release                                # output: build/app/outputs/flutter-apk/app-release.apk
```

Backend (`cd server`):

```bash
docker compose up --build    # API on :8080 + Postgres on :5432
dart test                    # server tests
dart run bin/server.dart     # run directly (needs DATABASE_URL, JWT_SECRET, PORT env vars)
```

## Architecture

### Offline-first with a repository switch

The app runs fully offline by default. Every data domain has an abstract repository interface with two implementations: a `Mock*` (in `data/repositories/mock_repositories.dart`, in-memory + SharedPreferences) and an `Api*` (in `data/repositories/api_repositories.dart`, talks to the backend via Dio).

The switch is `AppConstants.apiBaseUrl` (`String.fromEnvironment('API_BASE_URL')`, set via `--dart-define`). Each repository provider in `core/state/app_controller.dart` checks `if (AppConstants.apiBaseUrl.isNotEmpty)` to pick the API impl, else the mock. **When adding a new data domain, you must provide both implementations and wire a provider this way** — otherwise demo mode breaks.

### State management

- Riverpod throughout. The hub is `AppController` (`core/state/app_controller.dart`, ~2200 lines), a `Notifier<AppState>` exposed as `appControllerProvider`. It owns auth, profile, lessons, custom words, review, study plan, notifications, lottery, rewards, and persistence. `AppState` (`core/state/app_state.dart`) is the immutable state object.
- UI reads narrow slices with `ref.watch(appControllerProvider.select((s) => ...))`.
- Repository providers (`authRepositoryProvider`, `learningRepositoryProvider`, etc.) are also defined in `app_controller.dart`.

### Navigation

GoRouter, configured in `core/routing/app_router.dart` (`routerProvider`). A `ShellRoute` wraps the five bottom-tab destinations (`/home`, `/training`, `/ai-learning`, `/discover`, `/profile`, plus `/quest`) in `features/shell/app_shell.dart`; everything else (lesson flow, settings, wordbook detail, etc.) is a top-level route. Add new screens by registering a `GoRoute` here and placing the screen under `features/<area>/`.

### Feature organization

`lib/features/<area>/` holds screens (one folder per product area: auth, home, learning, quiz, review, wordbook, quests, discover, study, training, profile, etc.). Shared/reusable widgets live in `core/widgets/`. Data models are in `data/models/`.

### Localization

Three locales: English (`app_en.arb`, the template), Chinese (`app_zh.arb`, the **default runtime locale**), Malay (`app_ms.arb`). Config in `l10n.yaml`. Generated code in `lib/l10n/generated/` **is committed** — run `flutter gen-l10n` after editing `.arb` files and commit the result. User-facing strings must go through `AppLocalizations` (accessed via `AppLocalizations.of(context)`); `core/utils/ui_labels.dart` maps domain values (exam targets, etc.) to localized labels.

### Design system & UI guardrails

`core/theme/app_tokens.dart` is the single source of truth for spacing, radii, durations, and the "Friendly Quest" brand palette. Use `AppTokens.*` rather than hard-coded values; `app_theme.dart` builds the Material 3 light/dark themes from them.

`test/ui_style_guard_test.dart` enforces the flat visual style: feature screens must **not** use `BoxShadow`, `LinearGradient`/`RadialGradient`, `BackdropFilter`/blur, positive `elevation:`, `Chip`/`ChoiceChip`/`SegmentedButton`/`CheckboxListTile`, or the removed `QuestCard`/`MetricTile` abstractions (`home_screen.dart` is the only `Card` exception). This test will fail CI-style checks if you reintroduce heavy UI treatments — prefer the shared primitives in `core/widgets/` (e.g. `QuestPanel`, `SegmentedTabs`, `StatTile`, `ProgressRing`).

### Backend

`server/bin/server.dart` boots config + DB + router. `lib/src/routes.dart` defines all `shelf_router` endpoints (see README for the full endpoint table). Business rules are isolated in `*_policy.dart` files (`review_policy.dart`, `reward_policy.dart`, `study_plan_policy.dart`, `lottery_policy.dart`, etc.). `database.dart` owns the connection and runs idempotent `CREATE TABLE IF NOT EXISTS` migrations on startup. Auth is JWT (`auth.dart`). Config comes from env vars (`PORT`, `DATABASE_URL`, `JWT_SECRET`) via `config.dart`.

## Conventions

- Before opening a PR: `flutter analyze` and `flutter test` must pass (lints from `flutter_lints` via `analysis_options.yaml`).
- Branch from `main`; keep commits focused.
- `LinguaQuest_Product_Blueprint.md` and `LinguaQuest_PRD_Development_Guide.md` capture product intent and flow.

## 工程质量优先原则

**用时间和 token 换取工程质量。不允许为了节省 token 而偷懒。**

### 反偷懒铁律

以下行为**绝对禁止**，违者即为偷懒：

1. **禁止跳过流程步骤** — 任何非平凡任务必须走完完整流程：brainstorming → design → plan → implement → review → verify。跳过任一环节 = 偷懒。
2. **禁止无证据断言** — 绝不可以说"测试通过"、"编译成功"、"服务正常"而不贴出实际运行输出。Claims require evidence, always.
3. **禁止代码摘要** — 不可以写"// 同上"、"similar to above"、"依此类推"来省略实际代码。每一步都必须给出完整可运行的代码。
4. **禁止跳过 Review** — Spec compliance review 和 Code quality review 缺一不可。Review 发现的问题必须修复并重新 review，不可跳过 re-review。
5. **禁止假执行** — 不要"假装"运行了命令。每次运行命令必须展示实际输出。如果命令会失败，展示失败并解释。
6. **禁止偷工减料的实现** — 必须按照 spec/plan 完整实现，不可自行删减需求。YAGNI 是去掉不需要的东西，不是去掉需要的东西。

### 流程纪律

- **Brainstorming 必须做** — 任何 feature/功能开发，无论多"简单"，必须先 brainstorming。看似简单的东西最容易因为未检查的假设而浪费大量时间。
- **Plan 必须完整** — 计划中每一个 task 必须包含精确的文件路径、完整的代码块、确切的运行命令和预期输出。TBD/TODO/占位符 = 计划失败。
- **TDD 默认开启** — 除非项目无测试框架，否则先写 failing test → 再写实现 → 验证 pass。
- **Review 不可跳过** — 每个 task 完成后：spec compliance review → fix → re-review → code quality review → fix → re-review。两阶段都要过。

### 验证纪律

- 每次声称"完成"前，必须运行验证命令并贴出输出。
- 每次声称"测试通过"前，必须实际运行测试并贴出结果。
- 每次声称"服务正常"前，必须 curl/wget 并展示 HTTP 状态码和响应。
- 不可仅凭 TypeScript 编译通过就声称"没问题"——lint、build、runtime 行为都需要验证。

### Token 预算态度

- **不设上限** — 用户明确表示愿意用时间和 token 换工程质量。宁可多花 token 把事做对，不可为了省 token 留下隐患。
- **多 agent 并行** — 独立的探索、review、验证任务应该并行派发 agent，而不是串行省 token。
- **完整 review** — Review agent 必须完整读取所有改动文件，不可只看 diff 就下结论。