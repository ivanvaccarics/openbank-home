# Security

This repository describes a system that touches **personal financial data**.
The rules below are not optional.

---

## What this repository contains

✅ Configuration templates, Docker Compose definitions, shell scripts, documentation.

❌ It must **never** contain:

| Secret / data | Where it actually lives |
|---|---|
| Enable Banking Application ID | `.env` (git-ignored) |
| Enable Banking private key (`.pem`) | `secrets/`, `chmod 400`, mounted read-only |
| Actual Budget server password | `.env` |
| Actual end-to-end encryption password | Your password manager only — never on disk |
| Tailscale auth key | `.env` |
| IBANs, account IDs, balances, transactions | `data/` volume — git-ignored, never leaves the host |
| Real tailnet hostname | `.env` (docs use `raspberrypi.tailnet-XXXX.ts.net`) |

---

## Defence in depth

1. **`.gitignore` first.** It is the first commit in this repository's history, and
   it excludes by *pattern* rather than by allowlist. A new secret file type is
   ignored by default, not by luck.
2. **`gitleaks` pre-commit hook** — see [`.pre-commit-config.yaml`](.pre-commit-config.yaml).
   Install with `pre-commit install`.
3. **`gitleaks` in CI** — see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).
4. **GitHub Secret scanning + Push protection** — enable both in
   *Settings → Code security and analysis*. Free on public repositories.
5. **File permissions** — `chmod 400` on the `.pem`, mounted `:ro` in the container.

---

## ⚠️ If a secret is ever committed

**Revoke it. Do not merely delete it.**

Once a commit is pushed to a public repository, it is public forever — forks,
clones, caches and third-party mirrors may retain it even after a force-push or
history rewrite.

| Leaked item | Action |
|---|---|
| Enable Banking `.pem` / App ID | Delete the application at [enablebanking.com/cp/applications](https://enablebanking.com/cp/applications), create a new one, relink accounts |
| Tailscale auth key | Revoke in the Tailscale admin console → *Settings → Keys* |
| Actual server password | Change it in Actual, then rotate on every client |
| Actual E2EE password | Re-encrypt the budget with a new password |

Only *after* revoking should you clean history (`git filter-repo`, BFG) — and
treat that as cosmetic, not remediation.

---

## Threat model

### What this setup protects against

- **Internet-facing attacks** — nothing listens on a public interface. The only
  ingress is Tailscale (WireGuard), authenticated by device.
- **Third-party data custody** — no cloud finance provider holds your data;
  Enable Banking sees it in transit only, as a licensed AISP must.
- **Credential leakage via git** — layered scanning as described above.

### What it does **not** protect against

- **A compromised host.** Root on the Pi means access to `data/` and the `.pem`.
  Keep the OS patched, use SSH keys, disable password login.
- **A compromised Tailscale account.** Enable 2FA on it, and review the device
  list periodically.
- **Enable Banking credentials at rest.** The `.pem` and App ID are stored in
  the sync-server's `account.sqlite` in readable form — the server must be able
  to use them. Actual's end-to-end encryption is *client-side* and does **not**
  cover this file. **Encrypt your backups.** See [docs/backup-restore.md](docs/backup-restore.md).
- **Physical access** to an unencrypted SD card or disk. Consider full-disk encryption.

### Access model

Enable Banking access is granted through PSD2 **AISP** scope — *read-only*.
It cannot initiate payments. Consents expire every 90 days and must be renewed
with Strong Customer Authentication.

---

## Reporting a vulnerability

Open a [private security advisory](https://github.com/ivanvaccarics/openbank-home/security/advisories/new)
rather than a public issue. Please do not include real account data in reports.
