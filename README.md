# openbank-home

> Self-hosted personal finance: **Actual Budget** + **Enable Banking** (PSD2 / Open Banking) + **Tailscale**, running on a Raspberry Pi at home. No ports exposed to the internet.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/ivanvaccarics/openbank-home/actions/workflows/ci.yml/badge.svg)](https://github.com/ivanvaccarics/openbank-home/actions/workflows/ci.yml)
[![Self-hosted](https://img.shields.io/badge/self--hosted-yes-blue)](https://actualbudget.org)

Automatically pulls transactions from supported European banks through PSD2/Open
Banking into a local Actual Budget instance you can browse, edit, categorise and
export from your phone.

---

## Table of contents

| Document | What it covers |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Data flow, why PSD2 is not real-time, pending vs booked |
| [docs/enable-banking-setup.md](docs/enable-banking-setup.md) | Creating the Enable Banking app, the `.pem` key, linking banks |
| [docs/tailscale-setup.md](docs/tailscale-setup.md) | Tailnet, MagicDNS, HTTPS via `tailscale serve` |
| [docs/backup-restore.md](docs/backup-restore.md) | Cron backups, encryption, restore drill |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Consent expiry, rate limits, duplicates, cert issues |
| [docs/alternatives.md](docs/alternatives.md) | Actual vs Firefly III, aggregator comparison, community bridges |
| [SECURITY.md](SECURITY.md) | Threat model and secret-handling rules |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |

---

## Architecture

```text
  Phone / Laptop
        │
        │  Tailscale (WireGuard, end-to-end encrypted)
        ▼
  ┌─────────────────────────────────────────────┐
  │  Raspberry Pi / home server                 │
  │                                             │
  │   ┌───────────────────────────────────┐     │
  │   │  Actual Budget sync-server        │     │
  │   │  + Enable Banking integration     │     │
  │   │  + PostgreSQL/SQLite state        │     │
  │   └───────────────┬───────────────────┘     │
  │                   │                         │
  └───────────────────┼─────────────────────────┘
                      │  outbound HTTPS only
                      ▼
            Enable Banking API (PSD2)
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
    Bank A      Bank B      Bank C
```

**Key property:** the Pi only makes *outbound* connections to Enable Banking.
Nothing is reachable from the public internet. Your phone reaches Actual over
the tailnet, which gives you a **valid HTTPS certificate** for free via
`tailscale serve` — no domain to buy, no port forwarding, no reverse proxy.

A useful consequence: **bank sync keeps working with the VPN off**, because the
Pi initiates the calls. You only turn on Tailscale when you want to *look at*
your data.

---

## Why Enable Banking?

| | Enable Banking | GoCardless (Nordigen) | Tink / Salt Edge |
|---|---|---|---|
| Free tier for personal use | ✅ Yes, non-commercial | ⚠️ Increasingly restricted | ❌ Commercial only |
| European bank coverage | ~2,700 institutions | Large | Large |
| Coverage for supported banks | Good | Variable | Good |
| Native Actual Budget support | ✅ Yes (experimental) | ✅ Yes | ❌ No |
| Auth model | Private key (`.pem`) | Client ID + secret | OAuth / commercial |

See [docs/alternatives.md](docs/alternatives.md) for the full comparison.

---

## Prerequisites

- A machine that stays on: Raspberry Pi 4/5, NAS, or mini PC (~5 W)
- **Docker** and **Docker Compose v2**
- A free [Tailscale](https://tailscale.com) account
- A free [Enable Banking](https://enablebanking.com) account
- Your banks present in the Enable Banking institution list — **verify this first**,
  it is the go/no-go for the whole project

---

## Quick start

```bash
git clone https://github.com/ivanvaccarics/openbank-home.git
cd openbank-home

# 1. Configure
cp .env.example .env
$EDITOR .env

# 2. Join Tailscale, retrieve the node's DNS name, and update .env
tailscale up
tailscale status --json
$EDITOR .env

# 3. Bring the stack up
docker compose up -d

# 4. Expose it inside your tailnet (HTTPS, tailnet-only)
./scripts/tailscale-serve.sh
```

Open `https://<your-host>.<your-tailnet>.ts.net` from a device on the tailnet.
After verifying HTTPS, create the Enable Banking application with the callback
URL, protect its private key, and configure Bank Sync in Actual.

Full walkthrough: [docs/enable-banking-setup.md](docs/enable-banking-setup.md)
and [docs/tailscale-setup.md](docs/tailscale-setup.md).

---

## Scripts

| Script | Purpose |
|---|---|
| [`scripts/backup.sh`](scripts/backup.sh) | Snapshot the data volume, rotate old backups, optional `rclone` off-site |
| [`scripts/restore.sh`](scripts/restore.sh) | Restore a snapshot, with confirmation prompt |
| [`scripts/tailscale-serve.sh`](scripts/tailscale-serve.sh) | Publish Actual inside the tailnet over HTTPS |
| [`scripts/check-consents.sh`](scripts/check-consents.sh) | Remind you before PSD2 consents expire (90 days) |

Every script supports `--help`.

---

## Security

This repository is public. It contains **configuration and code only** — never
secrets, IBANs, account identifiers or transaction data.

- `.gitignore` was the very first commit, and excludes by pattern (`.env`, `*.pem`, `data/`, `*.sqlite`, …)
- `gitleaks` runs in CI **and** as a pre-commit hook
- The Enable Banking private key is mounted read-only and referenced by path from `.env`
- Enable **Secret scanning** and **Push protection** in *Settings → Code security*

Read [SECURITY.md](SECURITY.md) before your first commit.

---

## Caveats

- Enable Banking support in Actual Budget is **experimental** — this stack uses the `edge` image
- PSD2 allows only **4 unattended API calls per day** per account; there is no push/webhook for retail accounts
- Bank consents expire every **90 days** and require re-authentication (SCA)
- Card payments stay `pending` for 1–3 days and the final amount can change

Details and workarounds in [docs/architecture.md](docs/architecture.md) and
[docs/troubleshooting.md](docs/troubleshooting.md).

---

## License

[MIT](LICENSE) © ivanvaccarics

Not affiliated with Actual Budget, Enable Banking, Tailscale, or any financial institution.
