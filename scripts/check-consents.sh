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
Usage:
  check-consents.sh [--help]
  check-consents.sh --list
  check-consents.sh --update <bank-name> <last-sca-date-YYYY-MM-DD>

Local helper for PSD2 consent reminders. Consents commonly expire every 90 days
and need re-authentication/SCA.

State file format (tab-separated):
  <bank-name>\t<YYYY-MM-DD>
EOF
}

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

CONSENT_STATE_FILE="${CONSENT_STATE_FILE:-$REPO_ROOT/config/local-consents.tsv}"
CONSENT_WARN_DAYS="${CONSENT_WARN_DAYS:-14}"
CONSENT_WINDOW_DAYS=90

mkdir -p -- "$(dirname "$CONSENT_STATE_FILE")"
touch "$CONSENT_STATE_FILE"

update_entry() {
  local bank_name="$1"
  local consent_date="$2"

  if ! date -d "$consent_date" +%F >/dev/null 2>&1; then
    log "Invalid date: $consent_date"
    exit 1
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  awk -F '\t' -v bank="$bank_name" '$1 != bank' "$CONSENT_STATE_FILE" > "$tmp_file"
  printf '%s\t%s\n' "$bank_name" "$consent_date" >> "$tmp_file"
  mv -- "$tmp_file" "$CONSENT_STATE_FILE"
  log "Updated consent date for: $bank_name"
}

list_status() {
  local now_epoch
  now_epoch="$(date +%s)"
  local found=0

  while IFS=$'\t' read -r bank_name consent_date; do
    [[ -z "${bank_name:-}" ]] && continue
    [[ "$bank_name" == \#* ]] && continue
    if ! date -d "$consent_date" +%s >/dev/null 2>&1; then
      log "Skipping invalid entry for $bank_name"
      continue
    fi

    found=1
    local start_epoch expiry_epoch days_left
    start_epoch="$(date -d "$consent_date" +%s)"
    expiry_epoch=$((start_epoch + CONSENT_WINDOW_DAYS * 86400))
    days_left=$(((expiry_epoch - now_epoch) / 86400))

    if (( days_left < 0 )); then
      printf '%s: EXPIRED (%d days ago) -> re-authenticate in Actual now\n' "$bank_name" "$((-days_left))"
    elif (( days_left <= CONSENT_WARN_DAYS )); then
      printf '%s: expires in %d days -> schedule SCA refresh soon\n' "$bank_name" "$days_left"
    else
      printf '%s: %d days remaining\n' "$bank_name" "$days_left"
    fi
  done < "$CONSENT_STATE_FILE"

  if (( found == 0 )); then
    log "No consent entries found. Use --update <bank> <YYYY-MM-DD>."
  fi
}

case "${1:---list}" in
  --help|-h)
    usage
    ;;
  --list)
    list_status
    ;;
  --update)
    if [[ $# -ne 3 ]]; then
      usage
      exit 1
    fi
    update_entry "$2" "$3"
    ;;
  *)
    usage
    exit 1
    ;;
esac
