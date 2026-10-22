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

if [[ ! -f ".env.prod" ]]; then
  echo "Missing .env.prod (container env_file). Create it with the runtime env (e.g. AI_PROVIDER, AI_API_KEY)." >&2
  exit 1
fi

# This VPS has 2 GiB RAM: don't compile Dart alongside the OpenCode runtime.
# Restore AI even if a build fails; the existing API stays up during the build.
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" stop opencode
trap '"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" up -d --no-deps opencode' EXIT
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" build api tts

# docker-compose v1 can fail to RECREATE containers on newer Docker engines with
# a stale `KeyError: ContainerConfig` error, which can leave the database stopped
# and risk it being recreated against an incompatible image. To stay safe:
#   1. Ensure db is up but NEVER recreate a running db (--no-recreate).
#   2. Remove and freshly create ONLY the api container (--no-deps), so the deploy
#      never touches the database container or its volume.
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" up -d --no-deps --no-recreate db
# TTS microservice (stateless — safe to recreate; api reaches it via http://tts:5002).
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" up -d --no-deps tts
# OpenCode is private to the Compose network; start it before switching the API.
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" up -d --no-deps opencode
trap - EXIT
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" rm -sf api || true
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" up -d --no-deps api
"${COMPOSE[@]}" --env-file .env -f "$COMPOSE_FILE" ps

echo "LinguaQuest server deployed from $APP_DIR"
