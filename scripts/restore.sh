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
Usage: restore.sh <backup-file> [--help]

Restore Actual data from a backup created by scripts/backup.sh.

Safety controls:
  - Requires explicit confirmation before destructive steps.
  - Preserves current data directory by moving it to a timestamped path.

Accepted backup formats:
  - .tar.gz
  - .tar.gz.gpg (requires private key for decryption)
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

BACKUP_DIR="${BACKUP_DIR:-$REPO_ROOT/backups}"
INPUT_PATH="$1"
if [[ "$INPUT_PATH" != /* ]]; then
  INPUT_PATH="$BACKUP_DIR/$INPUT_PATH"
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  log "Backup file not found: $INPUT_PATH"
  exit 1
fi

DATA_ROOT="$REPO_ROOT/data"
DATA_DIR="$DATA_ROOT/actual"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
PRESERVED_DIR="$DATA_ROOT/actual.pre-restore-${TIMESTAMP}"
TEMP_ARCHIVE=""
CONTAINER_STOPPED=0

restart_container_if_needed() {
  if (( CONTAINER_STOPPED == 1 )); then
    log "Restarting Actual container"
    docker compose -f "$REPO_ROOT/docker-compose.yml" start actual >/dev/null
    CONTAINER_STOPPED=0
  fi
  if [[ -n "$TEMP_ARCHIVE" && -f "$TEMP_ARCHIVE" ]]; then
    rm -f -- "$TEMP_ARCHIVE"
  fi
}

trap restart_container_if_needed EXIT

cat <<EOF
WARNING: This will replace current Actual data in:
  $DATA_DIR

A copy of current data will be preserved as:
  $PRESERVED_DIR

Backup to restore:
  $INPUT_PATH
EOF

read -r -p "Type RESTORE to continue: " CONFIRM
if [[ "$CONFIRM" != "RESTORE" ]]; then
  log "Restore aborted"
  exit 1
fi

mkdir -p -- "$DATA_ROOT"

log "Stopping Actual container"
docker compose -f "$REPO_ROOT/docker-compose.yml" stop actual >/dev/null
CONTAINER_STOPPED=1

if [[ -d "$DATA_DIR" ]]; then
  log "Preserving current data"
  mv -- "$DATA_DIR" "$PRESERVED_DIR"
fi

if [[ "$INPUT_PATH" == *.gpg ]]; then
  TEMP_ARCHIVE="$(mktemp --suffix=.tar.gz)"
  log "Decrypting backup archive"
  gpg --batch --yes --decrypt --output "$TEMP_ARCHIVE" "$INPUT_PATH"
  INPUT_PATH="$TEMP_ARCHIVE"
fi

log "Restoring backup archive"
tar -C "$DATA_ROOT" -xzf "$INPUT_PATH"

if [[ ! -d "$DATA_DIR" ]]; then
  log "Restore failed: expected data directory was not restored"
  exit 1
fi

log "Starting Actual container"
docker compose -f "$REPO_ROOT/docker-compose.yml" start actual >/dev/null
CONTAINER_STOPPED=0

log "Restore completed"
