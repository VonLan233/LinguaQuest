#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/linguaquest/server}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Docker Compose is required. Install the Docker compose plugin or docker-compose v1." >&2
  exit 1
fi

if [[ ! -f ".env" ]]; then
  echo "Missing .env. Copy .env.example to .env and set POSTGRES_PASSWORD, DATABASE_URL, and JWT_SECRET." >&2
  exit 1
fi

"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" build
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" up -d
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" ps

echo "LinguaQuest server deployed from $APP_DIR"
