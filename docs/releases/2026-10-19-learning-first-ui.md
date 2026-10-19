# Learning-first UI and offline language learning

Branch: `codex/learning-first-ui-offline`.

The Flutter home, daily practice and AI center now use the approved blue cat design. The companion has a centered symmetrical smile. Daily encouragement stays on one line. Light, dark and system themes persist, with matching status-bar contrast.

Practice separates selection, confirmation, feedback and advancing. Completed review attempts are saved immediately; a saved draft preserves confirmed feedback so reopening it does not record the answer twice. A failed review save offers retry before advancing.

## Language and books

Choose **Settings → Explanation language** independently of the learning language and wordbook. Chinese, Japanese and English can each explain all three starter books, including same-language definitions. Each starter book contains 24 everyday words. Japanese localization messages are included, and the server receives a separate helper language for AI explanations. English learning now resolves to English in AI prompts.

The existing HSK, JLPT and English exam books remain. They retain their existing dictionary content; they are not represented as fully translated editions. The offline-book screen shows the explanation languages supplied by each book. Starter books appear first in the chooser.

## Offline behavior

- Bundled books require no first download. Home → Offline wordbooks downloads or updates a durable copy from `/wordbooks/<id>`.
- Downloads are validated before replacing a saved copy. Refreshing content preserves downloaded books; removing a downloaded copy returns to the bundled edition.
- A previously signed-in account can reopen its cached profile, plan and words without internet. Basic study writes are stored locally and replayed on the next online launch. Caches and pending writes are keyed by account.
- Guest learning remains local. Login, AI, online audio and server rewards need a network connection. Basic text learning and review do not depend on them.
- HTTP validation/authentication errors remain errors. Transport failures may save supported study records locally. Study/review event IDs are idempotent on the server for interrupted uploads.

## Validation

- Flutter analyzer: no issues.
- Flutter suite: 708 tests passed; the saved-feedback round trip was also exercised directly.
- Server suite: 215 tests passed.
- Model tests cover nine explanation/learning language combinations and JSON round trips.
- Offline tests cover restart, replay, account isolation, authentication rejection and preserving a valid book after an invalid download.
- Browser QA checked both themes, single-line encouragement, Chinese explanations for Japanese practice, retained answer feedback, book selection after restart and a successful download from the production API.
- Six layout checks cover Chinese/Japanese/English home screens in both themes at 360 × 800.

## Deployment

The server binary and matching runtime were compiled in GitHub Actions, then assembled into a small image on `intro-server`. A candidate served public traffic while the normal API container changed, with connection-drain periods before removing either instance. OpenCode remained running.

- Image: `server_api:ui-20261019` (also `server_api:latest`).
- Rollback image: `server_api:rollback-ui-20261019`.
- Backup and deployment record: `/home/deploy/linguaquest/backups/ui-20261019`.
- Public health returned 200; all three starter downloads returned 24 valid words.
- The other 11 containers retained their IDs and start times. Database volumes and existing backups were not removed.

Android builds use version `1.2.0+5` and the production API URL. The workflow creates the normal package and a separate `.preview` package so a different historical debug-signing key does not require deleting the old installation's data.


## Android delivery

[Successful build and downloadable APKs](https://github.com/VonLan233/LinguaQuest/actions/runs/39200548541), application source commit `afe8974`.

- Normal package: `com.example.linguaquest`, APK SHA-256 `50ce175f0dcc9cd53887669e8e776a1fb6a427a36ec2f23fe0d301cc80d9307d`.
- Installed preview: `com.example.linguaquest.preview`, APK SHA-256 `7decb84de402cc6a497657911fbab1e1d40660adf602ec440d8da8e36c7b3753`.
- Phone package manager confirms preview version `1.2.0`, build `5`. The original `1.1.0` / build `4` remains installed; its signing key differs, so no uninstall or data clearing was used.
- The phone downloaded the Japanese starter book from production and showed “Downloaded · works offline”.


### Physical offline check

On Android 13, the installed preview completed 10 Japanese words (20 meaning-recognition/recall answers) with airplane mode enabled and Wi-Fi disabled. The pack saved successfully. A force-stop and cold launch, still offline, restored the selected book and `10 / 10` daily progress. Original network settings were restored afterward. This used the local guest account; the existing installed app's data was retained.
