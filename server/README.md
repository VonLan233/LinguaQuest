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

For the deployed API on `intro-server`, use:

```bash
cd ../linguaquest
flutter run --dart-define=API_BASE_URL=http://64.90.1.138:8080
```

## Endpoints

- `GET /health`
- `GET /wordbooks`
- `GET /wordbooks/:id`
- `GET /words?wordBookId=<id>&q=<query>`
- `GET /words/:id`
- `POST /auth/register`
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
