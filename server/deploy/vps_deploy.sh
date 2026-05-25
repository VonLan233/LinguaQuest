#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/linguaquest/server}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

if [[ ! -f ".env" ]]; then
  echo "Missing .env. Copy .env.example to .env and set POSTGRES_PASSWORD, DATABASE_URL, and JWT_SECRET." >&2
  exit 1
fi

docker compose -f "$COMPOSE_FILE" --env-file .env build
docker compose -f "$COMPOSE_FILE" --env-file .env up -d
docker compose -f "$COMPOSE_FILE" --env-file .env ps

echo "LinguaQuest server deployed from $APP_DIR"
