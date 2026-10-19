# OpenCode Zen Free Service Maintenance Implementation Plan

> Execute inline in this maintenance session; the user authorized local changes, remote maintenance, atomic commits, and a GitHub push.

**Goal:** Restore LinguaQuest AI on `intro-server` using a currently available OpenCode Zen free model.

**Architecture:** Use the official `opencode serve` session API inside a private Docker service. Add a Dart provider that reuses the existing learning prompts, creates an isolated session for each request, parses its JSON answer, and deletes the session. Keep the existing OpenAI-compatible provider available for authenticated providers.

**Tech Stack:** Dart shelf/http, OpenCode CLI, Docker Compose, PostgreSQL (unchanged).

## Constraints and evidence

- Branch: `codex/maintain-opencode-zen-free`, based on current `origin/main`.
- Existing remote Zen key returns `401 api_key_expired`.
- Direct free-model calls return `403 FreeTierError`; use the actual OpenCode runtime.
- Check the live model catalog and test `deepseek-v4.1-flash-free` before deployment; never substitute a paid model.
- OpenCode must have no host checkout, Docker socket, production secrets, or public port. Require approval for every tool, never grant it from the API, disable sharing, and use internal basic authentication. Denying all tool schemas triggers upstream issue #50627.
- Preserve remote `.env`, database container, volumes, and unrelated services. Back up changed files and the current API image before deployment.
- Stage only explicitly named task files. Never commit secrets or unrelated local files.

## Task 1: Add the supported OpenCode service integration

**Files:** `server/lib/src/opencode_ai_provider.dart`, `server/lib/src/config.dart`, `server/lib/src/routes.dart`, `server/test/opencode_ai_provider_test.dart`, `server/test/config_test.dart`, `server/test/config_ai_model_test.dart`, `server/.env.example`, `server/docker-compose.prod.yml`, `server/opencode/opencode.json`, `server/deploy/vps_deploy.sh`, `server/README.md`, `server/.dockerignore`.

- [x] Add regression checks for session creation, prompt/model forwarding, JSON parsing, authentication, errors, and cleanup.
- [x] Configure `AI_PROVIDER=opencode`, `OPENCODE_SERVER_URL=http://opencode:4096`, and an internal `OPENCODE_SERVER_PASSWORD`; keep `AI_PROVIDER=mock` as the development default.
- [x] Reuse `buildSystemPrompt`, `AiRequest`, and `AiResponse`; preserve cloze model overrides and existing policy/history handling.
- [x] Add a pinned OpenCode container with all tools requiring approval, no published port, and a dedicated empty workspace.
- [x] Run `dart test`, targeted `dart analyze`, and Compose configuration checks. Commit the complete integration as one atomic change.

## Task 2: Deploy and verify

- [x] Back up only the affected remote files and tag the existing API image for rollback.
- [x] Synchronize the exact changed source and deployment files; update only the AI runtime settings in remote `.env.prod`.
- [x] Build the API and start OpenCode while the existing API continues serving. Probe OpenCode with the real learning prompt and free model.
- [x] Recreate only the API after upstream validation; verify `/health` and authenticated AI chat/cloze requests, then remove temporary smoke-test history.
- [x] Record the verified runtime/model and rollback procedure in `server/README.md`; push the maintenance branch to GitHub.

## Verification commands

```bash
cd server
dart test
dart analyze lib/src/opencode_ai_provider.dart lib/src/config.dart test/opencode_ai_provider_test.dart test/config_test.dart test/config_ai_model_test.dart
# Remote: validate interpolation without printing resolved secrets.
docker-compose --env-file .env -f docker-compose.prod.yml config --quiet
curl --fail http://127.0.0.1:8080/health
git push -u origin codex/maintain-opencode-zen-free
```

Sources checked on 2026-10-19: [models](https://opencode.ai/v2/docs/console/models/), [inference API](https://opencode.ai/v2/docs/console/api/inference/), [headless server](https://opencode.ai/docs/server/).

## Validation results

- Backend: all 205 tests passed on Dart 3.12.0; targeted static analysis reported no issues.
- Production API image: `server_api:zen-20261019`; rollback: `server_api:rollback-zen-20261019`.
- Upstream probe: OpenCode 1.19.3 + `deepseek-v4.1-flash-free`, valid teaching JSON in 15.7 seconds; session cleanup succeeded.
- Runtime memory: 640 MiB, no swap for the OpenCode container. Do not run Dart compilation and OpenCode simultaneously on the 2 GiB host.
- Host maintenance: removed unused public base-image/package-list caches and added a temporary 256 MiB swap file `/swapfile-linguaquest-zen` (not added to fstab). No database volumes were removed.
- Remote backup: `/home/deploy/linguaquest/backups/zen-20261019`, private to the deployment user.
- Live API: authenticated `/ai/chat` returned 200 in 2.8 s and `/ai/cloze` returned 200 in 4.6 s; both schemas passed, and their two temporary history rows were deleted.
- Public HTTPS `/health` returned 200. Original PostgreSQL and TTS containers stayed in place.
- Deployment build-failure simulation confirmed the EXIT trap restores OpenCode without replacing the API or touching the database.
