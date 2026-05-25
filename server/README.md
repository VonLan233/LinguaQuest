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

## Endpoints

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET /me`
- `GET /custom-words`
- `POST /custom-words`
- `PATCH /custom-words/:id`
- `DELETE /custom-words/:id`
- `POST /study-sessions`
- `GET /review/due`
- `POST /review-events`

## Production VPS Deploy

1. Copy this `server/` directory to the VPS, for example `/opt/linguaquest/server`.
2. Copy `.env.example` to `.env` and set strong production values.
3. Run:

```bash
chmod +x deploy/vps_deploy.sh
./deploy/vps_deploy.sh
```

The production compose file is `docker-compose.prod.yml`. It keeps PostgreSQL on a named volume and exposes the API on `PORT`.
