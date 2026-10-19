# Learning-first UI and offline language learning implementation plan

> Execution: implement inline in this session, validating each independent change before its atomic commit.

**Goal:** Apply the approved blue cat design to the Flutter app, support Chinese/Japanese/English explanation and study languages, and retain basic learning without a network connection.

**Architecture:** Keep the current Riverpod controller, routing, lesson builder and spaced repetition. Add multilingual starter content and persistent offline copies at repository boundaries; retain server authentication and validation. Reuse the current theme system and shared widgets for the three redesigned screens.

**Tech Stack:** Flutter 3.41.6, Dart 3.11, Riverpod, Dio, SharedPreferences, existing Dart API.

## Global Constraints

- Blue and cat elements; centered symmetrical smile.
- Single-line daily encouragement; light and dark themes.
- Chinese, Japanese and English explanation languages independently selectable from the learning language.
- Downloaded books survive process restart; bundled books remain available offline.
- Basic study, review and saved progress continue offline; account caches remain isolated.
- Preserve existing services, databases, backups and unrelated local files.
- Branch `codex/learning-first-ui-offline`; atomic commits pushed to GitHub.

### Task 1: Language combinations and truthful starter content

**Files:** `linguaquest/lib/app.dart`, `linguaquest/lib/data/models/lesson.dart`, `linguaquest/lib/data/wordbook_asset_loader.dart`, `linguaquest/lib/assets/data/`, `linguaquest/lib/l10n/`, `linguaquest/lib/features/profile/settings_screen.dart`, `linguaquest/test/data/multilingual_starter_test.dart`, `linguaquest/test/app_locale_test.dart`.

- [x] Add backward-compatible `localizedDefinitions` and Japanese book titles to JSON; prefer explicit translations over legacy heuristics.
- [x] Bundle curated Chinese, Japanese and English starter books with distinct definitions for all three explanation languages, including monolingual definitions.
- [x] Remove the English locale lock and add Japanese localization plus an explicit explanation-language setting.
- [x] Check the nine starter-book/explanation-language combinations and JSON round trips; regenerate localization code.
- [x] Commit `feat(learning): support Chinese Japanese and English language pairs`.

### Task 2: Persistent offline study and wordbook downloads

**Files:** `linguaquest/lib/data/remote/api_client.dart`, new `linguaquest/lib/data/remote/offline_study_store.dart`, `linguaquest/lib/data/repositories/api_repositories.dart`, `linguaquest/lib/data/repositories/learning_repository.dart`, `linguaquest/lib/core/state/app_controller.dart`, new `linguaquest/lib/features/wordbook/offline_wordbooks_screen.dart`, `linguaquest/lib/core/routing/app_router.dart`, `linguaquest/test/data/offline_study_test.dart`.

- [x] Persist validated per-book JSON separately from refreshable memory caches; expose download, downloaded IDs and removal methods.
- [x] Cache authenticated profile, plan and user words by account; queue only replay-safe basic study writes on transport failure, retaining IDs. Never treat an HTTP rejection as offline success.
- [x] Restore local state after restart; do not overwrite unsynced local learning with stale remote progress. Online-only auxiliary features must not block startup or learning.
- [x] Add download status, update and removal UI; failed downloads preserve the previous copy.
- [x] Test restart, network loss, invalid download preservation, account isolation and rejection behavior.
- [x] Commit `feat(offline): persist wordbooks and basic study progress`.

### Task 3: Approved UI, centered cat and dark theme

**Files:** `linguaquest/lib/core/theme/`, `linguaquest/lib/core/widgets/`, `linguaquest/lib/assets/image/study_cat.png`, `linguaquest/lib/features/home/home_screen.dart`, `linguaquest/lib/features/study/mixed_study_session_screen.dart`, `linguaquest/lib/features/ai_learning/ai_learning_screen.dart`, `linguaquest/lib/features/shell/app_shell.dart`, relevant widget tests.

- [x] Copy the edited transparent mascot asset, keep one centered symmetrical smile, and apply semantic cool blue surfaces in both themes.
- [x] Home: compact brand header, one-line encouragement, one primary daily task with real progress and explicit wordbook/review/AI entries; retain existing learning routes.
- [x] Practice: quiet progress, readable word/options, explicit confirm/next and visible text feedback; preserve retry, review scheduling, exit drafts and completion behavior.
- [x] AI: one truthful connection requirement, current-word suggestion and six clearly named tools; preserve query context and routes.
- [x] Check small screens, large text and both themes, fix status-bar contrast, run relevant widget tests.
- [x] Commit coherent UI/theme changes separately from content and offline logic.

### Task 4: Release validation and Android delivery

**Files:** `.github/workflows/`, `linguaquest/pubspec.yaml`, this plan and release validation notes.

- [x] Run formatter, Flutter analyzer and full Flutter tests; run server tests if server sources/data changed.
- [x] Build a production-connected Android APK with `--dart-define=API_BASE_URL=https://api.vonlan233.top`; retain bundled offline books.
- [x] Install on the authorized Android phone; use the separate preview package when historical signing keys differ. Check theme/language selection and a full offline study/cold-restart round trip while preserving the original installation.
- [x] Record actual results and limitations, commit build configuration if changed, and push each atomic commit to GitHub.
