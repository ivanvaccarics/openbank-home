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

## Configure `BACKUP_GPG_RECIPIENT` in `.env`

`BACKUP_GPG_RECIPIENT` identifies the **public GPG key** used to encrypt backup archives.

- Recommended: full key fingerprint (least ambiguous)
- Alternatives: Key ID or key email

If `BACKUP_GPG_RECIPIENT=` is left empty, encryption is disabled and backups are kept as `.tar.gz`.

If `BACKUP_GPG_RECIPIENT` is set, `scripts/backup.sh` writes `.tar.gz.gpg` and removes the unencrypted `.tar.gz`.

### 1) Install GnuPG (Debian / Raspberry Pi OS)

```bash
sudo apt update
sudo apt install -y gnupg
```

### 2) Generate a key (run as the same user that runs backups)

```bash
gpg --full-generate-key
```

Do **not** run `gpg` with `sudo`: keys must live in the GPG keyring of the user running `scripts/backup.sh` (including cron jobs).

### 3) List keys and fingerprint

```bash
gpg --list-keys
gpg --list-keys --fingerprint
```

### 4) Set `BACKUP_GPG_RECIPIENT` in `.env`

```bash
# Preferred: full fingerprint
BACKUP_GPG_RECIPIENT=1234567890ABCDEF1234567890ABCDEF12345678

# Alternatives:
# BACKUP_GPG_RECIPIENT=90ABCDEF12345678
# BACKUP_GPG_RECIPIENT=your-email@example.com
```

### 5) Verify encryption by running a backup

```bash
./scripts/backup.sh
ls -1 backups/actual-daily-*.tar.gz*
```

Expected result:

- With `BACKUP_GPG_RECIPIENT` set: latest backup ends with `.tar.gz.gpg`
- With `BACKUP_GPG_RECIPIENT=` empty: latest backup ends with `.tar.gz`

If `docker compose` requires elevated privileges on your system, do not run `sudo ./scripts/backup.sh` (that would switch user and GPG keyring). Instead, run backups as a user that can use Docker directly (for example by adding the user to the `docker` group):

```bash
sudo usermod -aG docker "$USER"
```

Log out/in (or reboot) before retrying.

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

`scripts/restore.sh` handles `.gpg` backups automatically and decrypts before extracting.

Manual decryption example:

```bash
gpg --decrypt --output /tmp/backup-file.tar.gz /absolute/path/to/backup-file.tar.gz.gpg
```

Safety controls:

- Explicit `RESTORE` confirmation
- Existing `data/actual` is preserved as `data/actual.pre-restore-<timestamp>`

## Key custody and recovery risk

Keep the GPG private key and its passphrase in a secure place, with at least one offline copy stored separately from the Raspberry Pi.

If the private key or passphrase is lost, encrypted backups are not recoverable.

## Restore drill (recommended)

1. Pick latest backup.
2. Restore on a maintenance window.
3. Verify login, account list, and recent transactions.
4. Re-run sync and confirm no fatal errors.
5. Record drill date and outcome.
