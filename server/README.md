# LinguaQuest Server

Dart `shelf` API for the LinguaQuest Flutter app. It provides JWT auth, custom word CRUD, study session writes, and review event writes on PostgreSQL.

## Local Run

```bash
dart pub get
dart run bin/server.dart
```

The default database URL is:

```text
postgresql://linguaquest:linguaquest@localhost:5432/linguaquest?sslmode=disable
```

## Docker Compose

```bash
docker compose up --build
```

Then run Flutter with:

```bash
cd ../linguaquest
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

For the deployed API on `intro-server`, use the public HTTPS endpoint:

```bash
cd ../linguaquest
flutter run --dart-define=API_BASE_URL=https://api.vonlan233.top
```

(The raw `http://64.90.1.138:8080` still works for debugging, but release
builds must use the HTTPS endpoint — Android blocks cleartext by default.)

## Endpoints

- `GET /health`
- `GET /wordbooks`
- `GET /wordbooks/:id`
- `GET /words?wordBookId=<id>&q=<query>`
- `GET /words/:id`
- `POST /auth/register`
- `POST /auth/verify` (email OTP)
- `POST /auth/resend` (resend email OTP)
- `POST /auth/login`
- `GET /me`
- `PATCH /me`
- `GET /lessons`
- `GET /learning-progress`
- `POST /reward-claims`
- `GET /custom-words`
- `POST /custom-words`
- `PATCH /custom-words/:id`
- `DELETE /custom-words/:id`
- `POST /study-sessions`
- `GET /study-plan`
- `PUT /study-plan`
- `POST /study-plan/reset`
- `GET /review/due`
- `POST /review-events`

## Production VPS Deploy

The current `intro-server` deployment uses a local copy of this `server/`
directory at `/home/deploy/linguaquest/server`. Preserve the existing remote
`.env` file and Docker volume when updating the service.

1. Copy this `server/` directory to the VPS, excluding `.env`, `.dart_tool/`,
   build output, `.DS_Store`, Git metadata, and planning documents.
2. On the VPS, confirm `/home/deploy/linguaquest/server/.env` still exists.
3. Run:

```bash
chmod +x deploy/vps_deploy.sh
./deploy/vps_deploy.sh
```

The production compose file is `docker-compose.prod.yml`. It keeps PostgreSQL on a named volume and exposes the API on `PORT`. The deploy script supports both the Docker Compose plugin (`docker compose`) and legacy `docker-compose` v1.

Runtime secrets live in the remote `.env.prod` (git-ignored), which
`docker-compose.prod.yml` injects via `env_file`. This includes
`RESEND_API_KEY` and `MAIL_FROM` for OTP email delivery — set them there, not in
`.env` (the app reads container env vars only).

## AI with OpenCode Zen free models

Verified against the [current model catalog](https://opencode.ai/inference/v1/models)
and [official headless server API](https://opencode.ai/docs/server/) on
2026-10-19. Direct free-model requests can return `FreeTierError`, and the
previous Zen API key expired. Use the official OpenCode runtime for free models.
The verified deployment uses OpenCode 1.19.3 with a 640 MiB memory cap; live
chat and cloze requests both returned HTTP 200 after the update.

Set these values in the remote `.env.prod`:

```dotenv
AI_PROVIDER=opencode
AI_MODEL=deepseek-v4.1-flash-free
AI_CLOZE_MODEL=
OPENCODE_SERVER_URL=http://opencode:4096
OPENCODE_SERVER_PASSWORD=<long-random-internal-password>
```

Put the same `OPENCODE_SERVER_PASSWORD` in `.env` for Compose interpolation.
`AI_API_KEY` is unused in this mode. The pinned OpenCode container has no public
port, host checkout, Docker socket, or production secret file. Its dedicated
`tutor` agent requires approval for every tool and disables sharing. The API
never grants tool approvals; a tool request times out and is aborted. Using
`deny` for every tool triggers the upstream free-tier compatibility issue
[#50627](https://github.com/anomalyco/opencode/issues/50627). Each learning request
uses its own session, which is deleted afterward; application history and daily limits still
use the existing database. The provider rejects paid model IDs, including cloze
overrides. Free offerings and availability can change: recheck the live catalog
and test the actual learning prompts before changing `AI_MODEL`.

Deploy from `/home/deploy/linguaquest/server` with `./deploy/vps_deploy.sh`.
On this 2 GiB VPS, stop `opencode` while compiling Dart; the deploy script
restarts it even when a build fails. For an AI-only update, build `api`, start
`opencode`, probe the free model, then recreate only `api`; leave `db` and `tts` running. Before changing production,
back up the affected files and `.env`/`.env.prod` outside the build context and
tag the running API image. To roll back, restore those files and the saved API
image, then recreate only `api` with `--no-deps`; never remove the database volume.

`AI_PROVIDER=remote` remains available for direct OpenAI-compatible providers
with a valid API key. Its current default API base is
`https://opencode.ai/inference/openai/v1`; this mode does not bypass free-tier
client restrictions.

## Public HTTPS endpoint (nginx + TLS)

The API is served at `https://api.vonlan233.top`, terminated by the host nginx
and reverse-proxied to the dockerized server on `127.0.0.1:8080`.

1. DNS: add an A record `api.vonlan233.top` → the server's public IP.
2. nginx: install the reverse-proxy block (see
   `deploy/nginx/api.vonlan233.top.conf` for the file and exact commands). It is
   an additive `server_name`-specific block and does not affect other sites on
   the host.
3. TLS: `sudo certbot --nginx -d api.vonlan233.top --redirect` issues a Let's
   Encrypt certificate, adds the `:443` block, and enables HTTP→HTTPS redirect.
   Renewal is automatic via certbot's scheduled task.
