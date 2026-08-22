#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

usage() {
  cat <<'EOF'
Usage: tailscale-serve.sh [--help]

Configure tailscale serve in background mode so HTTPS traffic on tailnet
port 443 is proxied to Actual on localhost.

IMPORTANT SECURITY WARNING:
  Never use `tailscale funnel` for this service.
  Funnel publishes to the public internet. This setup must remain tailnet-only.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

ACTUAL_PORT="${ACTUAL_PORT:-5006}"
TS_SERVE_HTTPS_PORT="${TS_SERVE_HTTPS_PORT:-443}"

if ! command -v tailscale >/dev/null 2>&1; then
  log "tailscale command not found"
  exit 1
fi

if ! tailscale status >/dev/null 2>&1; then
  log "tailscale is not connected. Run: tailscale up"
  exit 1
fi

log "Configuring tailscale serve (tailnet-only HTTPS proxy)"
tailscale serve --bg --https="$TS_SERVE_HTTPS_PORT" "http://127.0.0.1:${ACTUAL_PORT}"

log "Serve configured"
log "WARNING: Do not run tailscale funnel for this service."
