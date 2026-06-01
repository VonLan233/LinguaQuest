# LinguaQuest Server

Dart `shelf` API for the LinguaQuest Flutter app. It provides JWT auth, word book seed data, target word progress, custom word CRUD, study session writes, review events, rewards, notifications, forum records, class progress, analytics, leaderboard, achievements, and AI tutor conversations on PostgreSQL.

## Local Run

```bash
dart pub get
dart run bin/server.dart
```

The default database URL is:

```text
postgresql://linguaquest:linguaquest@localhost:5432/linguaquest?sslmode=disable
```

AI requests are handled by `AI_PROVIDER`. The default `local` provider returns structured learning feedback from the backend service layer and applies the same safety checks. For a production-compatible provider, set:

```text
AI_PROVIDER=openai-compatible
AI_MODEL=<provider-model>
AI_API_KEY=<server-side-key>
AI_BASE_URL=<chat-completions-compatible-url>
AI_SAFETY_ENABLED=true
```

The API key stays on the server; the Flutter app only calls `POST /ai/complete`.

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
- `PATCH /me`
- `GET /custom-words`
- `POST /custom-words`
- `PATCH /custom-words/:id`
- `DELETE /custom-words/:id`
- `GET /word-books`
- `GET /study-plan`
- `PUT /study-plan`
- `DELETE /study-plan`
- `GET /user-words`
- `PUT /user-words/:wordId`
- `POST /study-sessions`
- `GET /review/due`
- `POST /review-events`
- `GET /activity/summary`
- `GET /classes`
- `POST /classes/join`
- `GET /classes/progress`
- `GET /rewards/tasks`
- `POST /rewards/claim`
- `POST /rewards/lottery`
- `GET /notifications`
- `PATCH /notifications/:id/read`
- `GET /forum/posts`
- `POST /forum/posts`
- `GET /forum/posts/:id`
- `POST /forum/posts/:id/comments`
- `POST /forum/posts/:id/like`
- `GET /ai/conversations`
- `GET /ai/conversations/:id`
- `DELETE /ai/conversations/:id`
- `POST /ai/complete`
- `GET /analytics/summary`
- `GET /leaderboard`
- `GET /achievements`

## AI Service

`lib/src/ai_service.dart` owns prompt routing, input length checks, blocked-term filtering, structured JSON generation, and provider fallback. Route handlers only authenticate, call the service, and persist the resulting conversation/messages. Conversation detail and delete endpoints enforce user ownership before returning or removing records.

## Production VPS Deploy

1. Copy this `server/` directory to the VPS, for example `/opt/linguaquest/server`.
2. Copy `.env.example` to `.env` and set strong production values.
3. Run:

```bash
chmod +x deploy/vps_deploy.sh
./deploy/vps_deploy.sh
```

The production compose file is `docker-compose.prod.yml`. It keeps PostgreSQL on a named volume and exposes the API on `PORT`. The deploy script supports both the Docker Compose plugin (`docker compose`) and legacy `docker-compose` v1.
