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
Usage: backup.sh [--help]

Create a consistent backup of Actual data by temporarily stopping the container,
then rotating backup files according to .env retention values.

Environment (.env):
  BACKUP_DIR             Directory where backups are stored (default: ./backups)
  BACKUP_KEEP_DAILY      Number of daily backups to keep (default: 7)
  BACKUP_KEEP_WEEKLY     Number of weekly backups to keep (default: 4)
  BACKUP_GPG_RECIPIENT   Optional GPG recipient for encryption
  RCLONE_REMOTE          Optional rclone destination (e.g. remote:openbank-home)

Notes:
  - The script never prints secret values.
  - If BACKUP_GPG_RECIPIENT is set, the resulting archive is encrypted.
  - If RCLONE_REMOTE is set, the resulting backup file is copied with rclone.
EOF
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

BACKUP_DIR="${BACKUP_DIR:-$REPO_ROOT/backups}"
BACKUP_KEEP_DAILY="${BACKUP_KEEP_DAILY:-7}"
BACKUP_KEEP_WEEKLY="${BACKUP_KEEP_WEEKLY:-4}"
BACKUP_GPG_RECIPIENT="${BACKUP_GPG_RECIPIENT:-}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"

DATA_DIR="$REPO_ROOT/data/actual"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DAILY_BASENAME="actual-daily-${TIMESTAMP}.tar.gz"
DAILY_PATH="$BACKUP_DIR/$DAILY_BASENAME"
FINAL_BACKUP_PATH="$DAILY_PATH"
WEEKDAY="$(date +%u)"
WEEKLY_PATH=""
CONTAINER_STOPPED=0

rotate_prefix() {
  local prefix="$1"
  local keep="$2"
  mapfile -t files < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${prefix}*" -printf '%f\n' | sort)
  local count="${#files[@]}"
  if (( count <= keep )); then
    return
  fi
  local remove_count=$((count - keep))
  local index
  for (( index=0; index<remove_count; index++ )); do
    local target="$BACKUP_DIR/${files[$index]}"
    log "Removing old backup: ${files[$index]}"
    rm -f -- "$target"
  done
}

restart_container_if_needed() {
  if (( CONTAINER_STOPPED == 1 )); then
    log "Restarting Actual container"
    docker compose -f "$REPO_ROOT/docker-compose.yml" start actual >/dev/null
    CONTAINER_STOPPED=0
  fi
}

trap restart_container_if_needed EXIT

if [[ ! -d "$DATA_DIR" ]]; then
  log "Data directory not found: $DATA_DIR"
  exit 1
fi

mkdir -p -- "$BACKUP_DIR"

log "Stopping Actual container for consistent backup"
docker compose -f "$REPO_ROOT/docker-compose.yml" stop actual >/dev/null
CONTAINER_STOPPED=1

log "Creating archive: $DAILY_BASENAME"
tar -C "$REPO_ROOT/data" -czf "$DAILY_PATH" actual

log "Starting Actual container"
docker compose -f "$REPO_ROOT/docker-compose.yml" start actual >/dev/null
CONTAINER_STOPPED=0

if [[ -n "$BACKUP_GPG_RECIPIENT" ]]; then
  log "Encrypting backup archive with GPG"
  gpg --batch --yes --trust-model always --encrypt --recipient "$BACKUP_GPG_RECIPIENT" --output "${DAILY_PATH}.gpg" "$DAILY_PATH"
  rm -f -- "$DAILY_PATH"
  FINAL_BACKUP_PATH="${DAILY_PATH}.gpg"
fi

if [[ "$WEEKDAY" == "1" ]]; then
  WEEKLY_PATH="$BACKUP_DIR/actual-weekly-${TIMESTAMP}.tar.gz"
  if [[ "$FINAL_BACKUP_PATH" == *.gpg ]]; then
    WEEKLY_PATH+=".gpg"
  fi
  cp -- "$FINAL_BACKUP_PATH" "$WEEKLY_PATH"
  log "Created weekly snapshot: $(basename "$WEEKLY_PATH")"
fi

rotate_prefix "actual-daily-" "$BACKUP_KEEP_DAILY"
rotate_prefix "actual-weekly-" "$BACKUP_KEEP_WEEKLY"

if [[ -n "$RCLONE_REMOTE" ]]; then
  log "Copying backup to rclone remote"
  rclone copy -- "$FINAL_BACKUP_PATH" "$RCLONE_REMOTE"
  if [[ -n "$WEEKLY_PATH" ]]; then
    rclone copy -- "$WEEKLY_PATH" "$RCLONE_REMOTE"
  fi
fi

log "Backup completed: $(basename "$FINAL_BACKUP_PATH")"
