#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"

log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

usage() {
  cat <<'EOF'
Usage: start.sh [--help]

Start or recreate the openbank-home Compose stack, then configure the
tailnet-only Tailscale Serve proxy. The command is safe to run repeatedly.
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ ! -f "$ENV_FILE" ]]; then
  log "Missing $ENV_FILE. Copy .env.example to .env and configure it first."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  log "docker command not found"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  log "Docker Compose v2 is not available"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  log "Docker is not running or the current user cannot access it"
  exit 1
fi

log "Starting the Docker Compose stack"
docker compose -f "$COMPOSE_FILE" up -d

log "Configuring Tailscale Serve"
"$SCRIPT_DIR/tailscale-serve.sh"

log "openbank-home is running"
