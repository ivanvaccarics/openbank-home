# Backup and restore

## Why backups are security-sensitive

Actual client-side end-to-end encryption protects synced budget payloads, but server-side bank connector secrets in `account.sqlite` are not covered by that client E2EE boundary.

Backups must therefore be encrypted at rest and in transit.

## What to back up

At minimum:

- `data/actual/` (includes `server-files/account.sqlite` and user files)
- `.env` (stored privately, never committed)
- Enable Banking private key file referenced by `ENABLE_BANKING_PEM_PATH`

## Create backups

```bash
./scripts/backup.sh
```

Behavior:

- Stops the Actual container briefly for consistency
- Creates timestamped daily backup
- Creates weekly snapshot on Mondays
- Rotates by `BACKUP_KEEP_DAILY` and `BACKUP_KEEP_WEEKLY`
- Optionally encrypts with `BACKUP_GPG_RECIPIENT`
- Optionally copies to `RCLONE_REMOTE`

## Cron example

Run daily at 03:30:

```cron
30 3 * * * cd /absolute/path/to/openbank-home && /usr/bin/env bash scripts/backup.sh >> /var/log/openbank-home-backup.log 2>&1
```

## Restore procedure

```bash
./scripts/restore.sh /absolute/path/to/backup-file.tar.gz
```

or encrypted:

```bash
./scripts/restore.sh /absolute/path/to/backup-file.tar.gz.gpg
```

Safety controls:

- Explicit `RESTORE` confirmation
- Existing `data/actual` is preserved as `data/actual.pre-restore-<timestamp>`

## Restore drill (recommended)

1. Pick latest backup.
2. Restore on a maintenance window.
3. Verify login, account list, and recent transactions.
4. Re-run sync and confirm no fatal errors.
5. Record drill date and outcome.
