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
