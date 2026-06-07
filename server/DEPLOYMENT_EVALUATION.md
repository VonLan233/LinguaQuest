# LinguaQuest Backend Deployment Evaluation

## Recommended Path: Dockerized Dart Server + Firebase Firestore

Use the included Dart `shelf` server with Firebase Firestore as the managed database. This keeps the current REST API stable for the Flutter app while removing PostgreSQL hosting and backup work from the deployment.

Best fit:

- VPS with Docker Compose for coursework demos and predictable API hosting.
- Render, Fly.io, or similar container hosting for managed deployment.
- Firebase Firestore for managed persistence, security rules, backups, and future mobile-native integration.

## Option Comparison

| Option | Pros | Cons | Recommendation |
| --- | --- | --- | --- |
| VPS + Docker Compose + Firestore | Keeps existing Dart API, minimal server ops, no database container | Requires Firebase service account management | Use for first Firebase-backed deployment |
| Render/Fly container + Firestore | Less VPS maintenance, direct Git-based deploys | Free/low tiers may sleep or throttle | Good second step |
| Flutter direct to Firebase | Fast mobile integration, fewer API hops | Larger client refactor and weaker fit for protected AI proxy endpoints | Defer until the app is ready for Firebase Auth |

## Production Checklist

- Replace `JWT_SECRET`.
- Set `FIREBASE_PROJECT_ID`.
- Set `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` from a service account JSON file.
- Do not commit Firebase credentials.
- Put API behind HTTPS.
- Add structured logs and request IDs.
- Add password reset and email verification.
- Restrict CORS origins for web builds.

## Current Deployment Artifacts

- `Dockerfile`: compiles the Dart server into a deployable executable.
- `docker-compose.yml`: local API container.
- `docker-compose.prod.yml`: VPS/container production API stack.
- `.env`: required production environment variables, kept out of Git.
- `deploy/vps_deploy.sh`: repeatable build/start script for a Linux host with Docker Compose.
