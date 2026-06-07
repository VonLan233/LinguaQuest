# LinguaQuest Backend Deployment Evaluation

## Recommended Path: Dockerized Dart Server + PostgreSQL

Use the included Dart `shelf` server, PostgreSQL, and Dockerfile. This satisfies the server deployment requirement, keeps the backend in Dart, and gives a clear upgrade path for auth, custom word CRUD, study sessions, review events, leaderboards, and classes.

Best fit:

- VPS with Docker Compose for coursework demos and predictable cost.
- Render, Fly.io, or similar container hosting for managed deployment.
- Managed PostgreSQL when moving beyond a single demo server.

## Option Comparison

| Option | Pros | Cons | Recommendation |
| --- | --- | --- | --- |
| VPS + Docker Compose | Full control, lowest conceptual gap, easy to show deployment artifacts | You own backups, TLS, updates, and monitoring | Use for first server deployment |
| Render/Fly container + managed PostgreSQL | Less ops work, direct Git-based deploys | Free/low tiers may sleep or throttle | Good second step |
| Firebase Auth/Firestore | Fastest mobile integration, minimal server ops | Not a self-hosted/server backend, less aligned with this implementation request | Keep as future alternative |

## Production Checklist

- Replace `JWT_SECRET`.
- Copy `.env.example` to `.env` and set a strong `POSTGRES_PASSWORD`.
- Put API behind HTTPS.
- Move PostgreSQL to a persistent managed database or backed-up volume.
- Add structured logs and request IDs.
- Add password reset and email verification.
- Add profile update endpoint before enabling full remote goal sync.
- Restrict CORS origins for web builds.

## Current Deployment Artifacts

- `Dockerfile`: compiles the Dart server into a deployable executable.
- `docker-compose.yml`: local development stack.
- `docker-compose.prod.yml`: VPS/container production stack.
- `.env.example`: required production environment variables.
- `deploy/vps_deploy.sh`: repeatable build/start script for a Linux host with Docker Compose.
